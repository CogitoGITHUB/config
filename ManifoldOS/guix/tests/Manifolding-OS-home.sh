# GNU Guix --- Functional package management for GNU
# Copyright © 2021-2023 Andrew Tropin <andrew@trop.in>
# Copyright © 2021 Oleg Pykhalov <go.wigust@gmail.com>
# Copyright © 2022-2023, 2025 Ludovic Courtès <ludo@gnu.org>
#
# This file is part of GNU Guix.
#
# GNU Guix is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or (at
# your option) any later version.
#
# GNU Guix is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

#
# Test the 'Manifolding-OS home' using the external store, if any.
#

set -e

Manifolding-OS home --version

container_supported ()
{
    if guile -c '((@ (Manifolding-OS scripts environment) assert-container-features))'
    then
	return 0
    else
	return 1
    fi
}

localstatedir="$(guile -c '(use-modules (Manifolding-OS config))(display %localstatedir)')"
NIX_STORE_DIR="$(guile -c '(use-modules (Manifolding-OS config))(display %storedir)')"
GUIX_DAEMON_SOCKET="$localstatedir/Manifolding-OS/daemon-socket/socket"
GUIX_BUILD_OPTIONS="--timeout=`guile -c '(use-modules (Manifolding-OS tests))(display %tests-build-timeout)'`"
export NIX_STORE_DIR GUIX_DAEMON_SOCKET GUIX_BUILD_OPTIONS

# Run tests only when a "real" daemon is available.
if ! guile -c '(use-modules (Manifolding-OS)) (exit (false-if-exception (open-connection)))'
then
    exit 77
fi

STORE_PARENT="$(dirname "$NIX_STORE_DIR")"
export STORE_PARENT
if test "$STORE_PARENT" = "/"; then exit 77; fi

test_directory="$(mktemp -d)"
trap 'chmod -Rf +w "$test_directory"; rm -rf "$test_directory"' EXIT

(
    cd "$test_directory" || exit 77

    cat > "home.scm" <<'EOF'
(use-modules (Manifolding-OS gexp)
             (gnu home)
             (gnu home services)
             (gnu home services shells)
             (gnu packages bash)
             (gnu services))

(home-environment
 (services
  (list
   (simple-service 'test-config
                   home-files-service-type
                   (list `(".config/test.conf"
                           ,(plain-file
                             "tmp-file.txt"
                             "the content of ~/.config/test.conf"))

                         `("symlink" ,(symlink-to "<test_directory>"))))

   (service home-bash-service-type
            (home-bash-configuration
             (Manifolding-OS-defaults? #t)
             (bashrc (list (local-file "dot-bashrc")))))

   (simple-service 'add-environment-variable
                   home-environment-variables-service-type
                   `(("TODAY" . "26 messidor")
                     ("SHELL" . ,(file-append bash "/bin/bash"))
                     ("BUILDHOST_TIME" . ,#~(strftime "%c"
                                             (localtime (current-time))))
                     ("STRING_WITH_ESCAPES" . "chars: \" /\\")
                     ("LITERAL" . ,(literal-string "${abc}"))))

   (simple-service 'home-bash-service-extension-test
                   home-bash-service-type
                   (home-bash-extension
                    (environment-variables
                      '(("PS1" . "$GUIX_ENVIRONMENT λ ")))
                    (aliases
                      `(("run" . "Manifolding-OS shell")
                        ("path" . ,(literal-string "echo $PATH"))))
                    (bashrc
                     (list
                      (plain-file
                       "bashrc-test-config.sh"
                       "# the content of bashrc-test-config.sh"))))))))
EOF

    sed -i "s,<test_directory>,$test_directory," home.scm
    echo -n "# dot-bashrc test file for Manifolding-OS home" > "dot-bashrc"

    # Check whether the graph commands work as expected.
    Manifolding-OS home extension-graph "home.scm" | grep 'label = "home-activation"'
    Manifolding-OS home extension-graph "home.scm" | grep 'label = "home-symlink-manager"'
    Manifolding-OS home extension-graph "home.scm" | grep 'label = "home"'

    # There are no Shepherd services so the one below must fail.
    Manifolding-OS home shepherd-graph "home.scm" && false

    if container_supported
    then
	# Run the home in a container.  Always use bash inside container for
        # reproducibility of the tests.
        # TODO: Make container independent from external environment variables.
        SHELL=bash
	Manifolding-OS home container home.scm -- true
	Manifolding-OS home container home.scm -- false && false
	test "$(Manifolding-OS home container home.scm -- echo '$HOME')" = "$HOME"
	Manifolding-OS home container home.scm -- cat '~/.config/test.conf' | \
	    grep "the content of"
	Manifolding-OS home container home.scm -- test -h '~/.bashrc'
	Manifolding-OS home container home.scm -- test -h '~/symlink'
	test "$(Manifolding-OS home container home.scm -- id -u)" = 1000
	Manifolding-OS home container home.scm -- test -f '$HOME/sample/home.scm' && false
	Manifolding-OS home container home.scm --expose="$PWD=$HOME/sample" -- \
	     test -f '$HOME/sample/home.scm'
	Manifolding-OS home container home.scm --expose="$PWD=$HOME/sample" -- \
	     rm -v '$HOME/sample/home.scm' && false
	Manifolding-OS home container home.scm -- touch /whatever && false
    else
	echo "'Manifolding-OS home container' test SKIPPED" >&2
    fi

    HOME="$test_directory"
    export HOME

    #
    # Test 'Manifolding-OS home reconfigure'.
    #

    echo "# This file will be overridden and backed up." > "$HOME/.bashrc"
    mkdir "$HOME/.config"
    echo "This file will be overridden too." > "$HOME/.config/test.conf"
    echo "This file will stay around." > "$HOME/.config/random-file"

    Manifolding-OS home reconfigure "${test_directory}/home.scm"
    test -d "${HOME}/.Manifolding-OS-home"
    test -h "${HOME}/.bash_profile"
    test -h "${HOME}/.bashrc"
    test -h "${HOME}/symlink"
    test "$(readlink -f $HOME/symlink)" == "$test_directory"
    grep 'alias run="Manifolding-OS shell"' "$HOME/.bashrc"
    grep "alias path='echo \$PATH'" "$HOME/.bashrc"
    test "$(tail -n 2 "${HOME}/.bashrc")" == "\
# dot-bashrc test file for Manifolding-OS home
# the content of bashrc-test-config.sh"
    grep -q "the content of ~/.config/test.conf" "${HOME}/.config/test.conf"
    grep '^export PS1="\$GUIX_ENVIRONMENT λ "$' "${HOME}/.bash_profile"

    ( . "${HOME}/.Manifolding-OS-home/setup-environment"; test "$TODAY" = "26 messidor" )
    ( . "${HOME}/.Manifolding-OS-home/setup-environment"; test "$LITERAL" = '${abc}' )
    ( . "${HOME}/.Manifolding-OS-home/setup-environment";
      test "$STRING_WITH_ESCAPES" = "chars: \" /\\")
    ( . "${HOME}/.Manifolding-OS-home/setup-environment";
      echo "$SHELL" | grep "/gnu/store/.*/bin/bash" )

    # This one should still be here.
    grep "stay around" "$HOME/.config/random-file"

    # Make sure preexisting files were backed up.
    grep "overridden" "$HOME"/*Manifolding-OS-home*backup/.bashrc
    grep "overridden" "$HOME"/*Manifolding-OS-home*backup/.config/test.conf
    rm -r "$HOME"/*Manifolding-OS-home*backup

    #
    # Test 'Manifolding-OS home describe'.
    #

    configuration_file()
    {
        Manifolding-OS home describe                      \
            | grep 'configuration file:'        \
            | cut -d : -f 2                     \
            | xargs echo
    }
    test "$(cat "$(configuration_file)")" == "$(cat home.scm)"

    canonical_file_name()
    {
        Manifolding-OS home describe                      \
            | grep 'canonical file name:'       \
            | cut -d : -f 2                     \
            | xargs echo
    }
    test "$(canonical_file_name)" == "$(readlink "${HOME}/.Manifolding-OS-home")"

    #
    # Configure a new generation.
    #

    # Change the bashrc snippet content and comment out one service.
    sed -i "home.scm" -e's/the content of/the NEW content of/g'
    sed -i "home.scm" -e"s/(simple-service 'test-config/#;(simple-service 'test-config/g"

    Manifolding-OS home reconfigure "${test_directory}/home.scm"
    test "$(tail -n 2 "${HOME}/.bashrc")" == "\
# dot-bashrc test file for Manifolding-OS home
# the NEW content of bashrc-test-config.sh"

    # This file must have been removed and not backed up.
    test ! -e "$HOME/.config/test.conf"
    test ! -e "$HOME"/*Manifolding-OS-home*backup/.config/test.conf

    test "$(cat "$(configuration_file)")" == "$(cat home.scm)"
    test "$(canonical_file_name)" == "$(readlink "${HOME}/.Manifolding-OS-home")"

    test $(Manifolding-OS home list-generations | grep "^Generation" | wc -l) -eq 2

    #
    # Test 'Manifolding-OS home search'.
    #

    Manifolding-OS home search mcron | grep "^name: home-mcron"
    Manifolding-OS home search scheduling daemon | grep "^name: home-mcron"
)
