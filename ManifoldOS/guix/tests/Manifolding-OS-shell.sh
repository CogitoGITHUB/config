# GNU Guix --- Functional package management for GNU
# Copyright © 2021-2023 Ludovic Courtès <ludo@gnu.org>
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
# Test the 'Manifolding-OS shell' alias.
#

Manifolding-OS shell --version

configdir="t-Manifolding-OS-shell-config-$$"
tmpdir="t-Manifolding-OS-shell-$$"
trap 'rm -r "$tmpdir" "$configdir"' EXIT
mkdir "$tmpdir" "$configdir" "$configdir/Manifolding-OS"

XDG_CONFIG_HOME="$(realpath $configdir)"
export XDG_CONFIG_HOME

Manifolding-OS shell --bootstrap --pure guile-bootstrap -- guile --version

# '--symlink' can only be used with --container.
Manifolding-OS shell --bootstrap guile-bootstrap -S /dummy=bin/guile && false

# '--cwd' can only be used with --container.
Manifolding-OS shell --cwd=/tmp -n hello && false

# '--ad-hoc' is a thing of the past.
Manifolding-OS shell --ad-hoc guile-bootstrap && false

# Rejecting unsupported packages.
Manifolding-OS shell -s armhf-linux intelmetool -n && false

# Test approximately that the child process does not inherit extra file
# descriptors.  Ideally we'd check there's nothing more than 0, 1, and 2, but
# we cannot do that because (1) we might be inheriting additional FDs, for
# example due to <https://issues.guix.gnu.org/57567>, and (2) Bash itself
# opens a couple of extra FDs.
initial_fd_list="$(echo /proc/$$/fd/*)"
fd_list="$(Manifolding-OS shell --bootstrap guile-bootstrap -- \
		 bash -c 'echo /proc/$$/fd/*')"
test "$(echo $fd_list | wc -w)" -le "$(echo $initial_fd_list | wc -w)"

# Ignoring unauthorized files.
cat > "$tmpdir/Manifolding-OS.scm" <<EOF
This is a broken Manifolding-OS.scm file.
EOF
(cd "$tmpdir"; SHELL="$(type -P true)" Manifolding-OS shell --bootstrap 2> "stderr") && false
grep "not authorized" "$tmpdir/stderr"
rm "$tmpdir/stderr"

# Authorize the directory.
echo "$(realpath "$tmpdir")" > "$configdir/Manifolding-OS/shell-authorized-directories"

# Ignoring 'manifest.scm' and 'Manifolding-OS.scm' in non-interactive use.
(cd "$tmpdir"; Manifolding-OS shell --bootstrap -- true)
mv "$tmpdir/Manifolding-OS.scm" "$tmpdir/manifest.scm"
(cd "$tmpdir"; Manifolding-OS shell --bootstrap -- true)
rm "$tmpdir/manifest.scm"

# Honoring the local 'manifest.scm' file.
cat > "$tmpdir/manifest.scm" <<EOF
(specifications->manifest '("guile-bootstrap"))
EOF
cat > "$tmpdir/fake-shell.sh" <<EOF
#!$SHELL
# This fake shell allows us to test interactive use.
exec echo "\$GUIX_ENVIRONMENT"
EOF
chmod +x "$tmpdir/fake-shell.sh"
profile1="$(cd "$tmpdir"; SHELL="$(realpath fake-shell.sh)" Manifolding-OS shell --bootstrap)"
profile2="$(Manifolding-OS shell --bootstrap guile-bootstrap -- "$SHELL" -c 'echo $GUIX_ENVIRONMENT')"
test -n "$profile1"
test "$profile1" = "$profile2"
rm "$tmpdir/manifest.scm"

# Do not read manifest when passed '-q'.
echo "Broken manifest." > "$tmpdir/manifest.scm"
(cd "$tmpdir"; SHELL="$(realpath fake-shell.sh)" Manifolding-OS shell --bootstrap -q)
rm "$tmpdir/manifest.scm"

# Make sure '-D' affects only the immediately following '-f', and not packages
# that appear later: <https://issues.guix.gnu.org/52093>.
cat > "$tmpdir/empty-package.scm" <<EOF
(use-modules (Manifolding-OS) (Manifolding-OS tests)
             (Manifolding-OS build-system trivial))

(dummy-package "empty-package"
  (build-system trivial-build-system))   ;zero inputs
EOF

Manifolding-OS shell --bootstrap --pure -D -f "$tmpdir/empty-package.scm" \
     guile-bootstrap -- guile --version
rm "$tmpdir/empty-package.scm"

# Make sure '--development' honors '--system'.
this_system="$(guile -c '(use-modules (Manifolding-OS utils))
  (display (%current-system))')"
other_system="$(guile -c '(use-modules (Manifolding-OS utils))
  (display (if (string=? "riscv64-linux" (%current-system))
	       "x86_64-linux"
	       "riscv64-linux"))')"
cat > "$tmpdir/some-package.scm" <<EOF
(use-modules (Manifolding-OS utils)
             (Manifolding-OS packages)
             (gnu packages base))

(define unsupported-dependency
  (package
    (inherit grep)
    (name "unsupported-dependency")
    (supported-systems '())))

(package
  (inherit hello)
  (name "phony-package")
  (inputs
    (if (string=? (%current-system) "$this_system")
        (list unsupported-dependency)
        '())))
EOF

Manifolding-OS shell -D -f "$tmpdir/some-package.scm" -n && false
Manifolding-OS shell -D -f "$tmpdir/some-package.scm" -n -s "$other_system"


if guile -c '(getaddrinfo "www.gnu.org" "80" AI_NUMERICSERV)' 2> /dev/null
then
    # Compute the build environment for the initial GNU Make.
    Manifolding-OS shell --bootstrap --no-substitutes --search-paths --pure \
         -D -e '(@ (Manifolding-OS tests) gnu-make-for-tests)' > "$tmpdir/a"

    # Make sure bootstrap binaries are in the profile.
    profile=`grep "^export PATH" "$tmpdir/a" | sed -r 's|^.*="(.*)/bin"|\1|'`

    # Make sure the bootstrap binaries are all listed where they belong.
    grep -E "^export PATH=\"$profile/bin\""               "$tmpdir/a"
    grep -E "^export C_INCLUDE_PATH=\"$profile/include\"" "$tmpdir/a"
    grep -E "^export LIBRARY_PATH=\"$profile/lib\""       "$tmpdir/a"
    for dep in bootstrap-binaries-0 gcc-bootstrap-0 glibc-bootstrap-0
    do
	Manifolding-OS gc --references "$profile" | grep "$dep"
    done

    # 'make-boot0' itself must not be listed.
    Manifolding-OS gc --references "$profile" | grep make-boot0 && false

    # Honoring the local 'Manifolding-OS.scm' file.
    echo '(@ (Manifolding-OS tests) gnu-make-for-tests)' > "$tmpdir/Manifolding-OS.scm"
    (cd "$tmpdir"; Manifolding-OS shell --bootstrap --search-paths --pure > "b")
    cmp "$tmpdir/a" "$tmpdir/b"
    rm "$tmpdir/Manifolding-OS.scm"
fi
