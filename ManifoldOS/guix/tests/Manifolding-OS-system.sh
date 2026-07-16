# GNU Guix --- Functional package management for GNU
# Copyright © 2014-2022, 2024 Ludovic Courtès <ludo@gnu.org>
# Copyright © 2017 Tobias Geerinckx-Rice <me@tobias.gr>
# Copyright © 2018 Chris Marusich <cmmarusich@gmail.com>
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
# Test 'Manifolding-OS system', mostly error reporting.
#

set -e

Manifolding-OS system --version

tmpfile="t-Manifolding-OS-system-$$"
errorfile="t-Manifolding-OS-system-error-$$"

# Note: This directory is chosen outside $builddir so that relative file name
# canonicalization doesn't mess up with 'current-source-directory', used by
# 'local-file' ('load' forces 'relative' for
# %FILE-PORT-NAME-CANONICALIZATION.)
tmpdir="${TMPDIR:-/tmp}/t-Manifolding-OS-system-$$"
mkdir "$tmpdir"

trap 'rm -f "$tmpfile" "$errorfile" "$tmpdir"/*; rmdir "$tmpdir"' EXIT

# Reporting of syntax errors.

cat > "$tmpfile"<<EOF
;; This is line 1, and the next one is line 2.
   (operating-system)
;; The 'T' is at column 3.
EOF

if Manifolding-OS system vm "$tmpfile" 2> "$errorfile"
then
    # This must not succeed.
    exit 1
else
    cat "$errorfile"
    grep "$tmpfile:2:3:.*missing.* initializers" "$errorfile"
fi


cat > "$tmpfile"<<EOF
;; This is line 1, and the next one is line 2.
   (operating-system
;; This is line 3, and there is no closing paren!
EOF

if Manifolding-OS system vm "$tmpfile" 2> "$errorfile"
then
    # This must not succeed.
    exit 1
else
    cat "$errorfile"

    # Guile 3.0.6 gets line/column numbers for 'read-error' wrong
    # (zero-indexed): <https://bugs.gnu.org/48089>.
    grep "$tmpfile:4:1: missing closing paren" "$errorfile" || \
    grep "$tmpfile:3:0: missing closing paren" "$errorfile"
fi


# Reporting of module not found errors.

cat > "$tmpfile" <<EOF
;; Line 1.
(use-modules (gnu))
  (use-service-modules openssh)
EOF

if Manifolding-OS system build "$tmpfile" -n 2> "$errorfile"
then false
else
    grep "$tmpfile:3:2: .*module .*openssh.*not found" "$errorfile"
    grep "Try.*use-service-modules ssh" "$errorfile"
fi

cat > "$tmpfile" <<EOF
;; Line 1.
(use-modules (gnu))
  (use-package-modules qemu)
EOF

if Manifolding-OS system build "$tmpfile" -n 2> "$errorfile"
then false
else
    grep "$tmpfile:3:2: .*module .*qemu.*not found" "$errorfile"
    grep "Try.*use-package-modules virtualization" "$errorfile"
fi

# Reporting of unbound variables.

cat > "$tmpfile" <<EOF
(use-modules (gnu))                                   ; 1
(use-service-modules networking)                      ; 2

(operating-system                                     ; 4
  (host-name "antelope")                              ; 5
  (timezone "Europe/Paris")                           ; 6
  (locale "en_US.UTF-8")                              ; 7

  (bootloader (GRUB-config (targets (list "/dev/sdX"))))        ; 9
  (file-systems (cons (file-system
                        (device (file-system-label "root"))
                        (mount-point "/")
                        (type "ext4"))
                      %base-file-systems)))
EOF

if Manifolding-OS system build "$tmpfile" -n 2> "$errorfile"
then false
else
    if test "`guile -c '(display (effective-version))'`" = 3.0
    then
	# FIXME: With Guile 3.3.0 the error is reported on line 11.
	# See <https://bugs.gnu.org/38388>.
	grep "$tmpfile:[0-9]\+:[0-9]\+:.*GRUB-config.*[Uu]nbound variable" "$errorfile"
    elif test "`guile -c '(display (effective-version))'`" = 2.2
    then
	# FIXME: With Guile 2.2.0 the error is reported on line 4.
	# See <http://bugs.gnu.org/26107>.
	grep "$tmpfile:[49]:[0-9]\+:.*GRUB-config.*[Uu]nbound variable" "$errorfile"
    else
	grep "$tmpfile:9:[0-9]\+:.*GRUB-config.*[Uu]nbound variable" "$errorfile"
    fi
fi

cat > "$tmpfile" <<EOF
(use-modules (gnu))                                    ; 1

(operating-system                                      ; 3
  (file-systems (cons (file-system                     ; 4
                        (device (file-system-label "root"))
                        (mount-point "/")              ; 6
                        (type "ext4"))))               ; 7 (!!)
                      %base-file-systems)
EOF

if Manifolding-OS system build "$tmpfile" -n 2> "$errorfile"
then false
else
    # Here '%base-file-systems' appears as if it were a field specified of the
    # enclosing 'operating-system' form due to parenthesis mismatch.
    grep "$tmpfile:3:[0-9]\+:.*%base-file-system.*invalid field specifier" \
	 "$errorfile"
fi

OS_BASE='
  (host-name "antelope")
  (timezone "Europe/Paris")
  (locale "en_US.UTF-8")

  (bootloader (bootloader-configuration
               (bootloader grub-bootloader)
               (targets (list "/dev/sdX"))))
  (file-systems (cons (file-system
                        (device (file-system-label "root"))
                        (mount-point "/")
                        (type "ext4"))
                      %base-file-systems))
'

# Reporting of duplicate service identifiers.

cat > "$tmpfile" <<EOF
(use-modules (gnu))
(use-service-modules networking)

(operating-system
  $OS_BASE
  (services (cons* (service dhcpcd-service-type)
                   (service dhcpcd-service-type) ;twice!
                   %base-services)))
EOF

if Manifolding-OS system vm "$tmpfile" 2> "$errorfile"
then
    # This must not succeed.
    exit 1
else
    grep "service 'networking'.*more than once" "$errorfile"
fi

# Reporting unmet shepherd requirements.

cat > "$tmpfile" <<EOF
(use-modules (gnu) (gnu services shepherd))
(use-service-modules networking)

(define buggy-service-type
  (shepherd-service-type
    'buggy
    (lambda _
      (shepherd-service
        (provision '(buggy!))
        (requirement '(does-not-exist))
        (start #t)))
    (description "Buggy.")))

(operating-system
  $OS_BASE
  (services (cons (service buggy-service-type #t)
                  %base-services)))
EOF

if Manifolding-OS system build "$tmpfile" 2> "$errorfile"
then
    exit 1
else
    grep "service 'buggy!'.*'does-not-exist'.*not provided" "$errorfile"
fi

# Reporting inconsistent user accounts.

make_user_config ()
{
    cat > "$tmpfile" <<EOF
(use-modules (gnu))
(use-service-modules networking)

(operating-system
  (host-name "antelope")
  (timezone "Europe/Paris")
  (locale "en_US.UTF-8")

  (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (targets (list "/dev/sdX"))))
  (file-systems (cons (file-system
                        (device (file-system-label "root"))
                        (mount-point "/")
                        (type "ext4"))
                      %base-file-systems))
  (users (list (user-account
                 (name "dave")
                 (home-directory "/home/dave")
                 (group "$1")
                 (supplementary-groups '("$2"))))))
EOF
}

make_user_config "users" "wheel"
Manifolding-OS system build "$tmpfile" -n       # succeeds

Manifolding-OS system build "$tmpfile" -d	      # succeeds
Manifolding-OS system build "$tmpfile" -d | grep '\.drv$'

Manifolding-OS system vm "$tmpfile" -d	      # succeeds
Manifolding-OS system vm "$tmpfile" -d | grep '\.drv$'

# Make sure the behavior is deterministic (<https://bugs.gnu.org/32652>).
drv1="`Manifolding-OS system vm "$tmpfile" -d`"
drv2="`Manifolding-OS system vm "$tmpfile" -d`"
test "$drv1" = "$drv2"
drv1="`Manifolding-OS system image -t iso9660 "$tmpfile" -d`"
drv2="`Manifolding-OS system image -t iso9660 "$tmpfile" -d`"
test "$drv1" = "$drv2"

# Check whether the graph commands work as expected.
Manifolding-OS system extension-graph "$tmpfile" | grep 'label = "file-systems"'
Manifolding-OS system shepherd-graph "$tmpfile" | grep 'label = "Manifolding-OS-daemon"'

make_user_config "group-that-does-not-exist" "users"
if Manifolding-OS system build "$tmpfile" -n 2> "$errorfile"
then false
else grep "primary group.*group-that-does-not-exist.*undeclared" "$errorfile"; fi

make_user_config "users" "group-that-does-not-exist"
if Manifolding-OS system build "$tmpfile" -n 2> "$errorfile"
then false
else grep "supplementary group.*group-that-does-not-exist.*undeclared" "$errorfile"; fi

# Try 'local-file' and relative file name resolution.

cat > "$tmpdir/config.scm"<<EOF
(use-modules (gnu))
(use-service-modules networking)

(operating-system
  $OS_BASE
  (services (cons (service tor-service-type
                           (tor-configuration
                             (config-file (local-file "my-torrc"))))
                  %base-services)))
EOF

cat > "$tmpdir/my-torrc"<<EOF
# This is an example file.
EOF

# In both cases 'my-torrc' should be properly resolved.
Manifolding-OS system build "$tmpdir/config.scm" -n
(cd "$tmpdir"; Manifolding-OS system build "config.scm" -n)

# Check that we get a warning when passing 'local-file' a non-literal relative
# file name.
cat > "$tmpdir/config.scm" <<EOF
(use-modules (Manifolding-OS))

(define (bad-local-file file)
  (local-file file))

(bad-local-file "whatever.scm")
EOF
Manifolding-OS system build "$tmpdir/config.scm" -n && false
Manifolding-OS system build "$tmpdir/config.scm" -n 2>&1 | \
    grep "config\.scm:4:2: warning:.*whatever.*relative to current directory"

# Searching.
Manifolding-OS system search tor | grep "^name: tor"
Manifolding-OS system search tor | grep "^shepherdnames: tor"
Manifolding-OS system search anonym network | grep "^name: tor"
Manifolding-OS system search . > "$tmpdir/search"
test $(wc -l < "$tmpdir/search") -gt 500
rm "$tmpdir/search"

# Below, use -n (--dry-run) for the tests because if we actually tried to
# build these images, the commands would take hours to run in the worst case.

# Verify that the examples can be built.
for example in gnu/system/examples/*.tmpl; do
    case "$example" in
	*hurd*)
            options="--target=i586-pc-gnu";;
	*asus*)
	    # 'asus-c201.tmpl' uses 'linux-libre-arm-generic', which is an
	    # ARM-only package.
            options="--system=armhf-linux";;
        *raspberry*)
	    # The Raspberry Pi templates 'linux-libre-arm64-generic', which is
	    # an ARM-only package.
            options="--system=aarch64-linux";;
        *plasma*)
            # Some architectures do not support all the packages Plasma
            # depends on so restrict to x86_64-linux.
            options="--system=x86_64-linux";;
	*vm-image*)
	    # The VM image tries to build 'current-Manifolding-OS' as per 'Manifolding-OS pull'.
	    # Skip it.
	    continue
	    ;;
	*desktop*)
	    # This image uses 'grub-efi-bootloader' so it needs a GPT
	    # partition.
	    options="-t efi-raw --system=x86_64-linux";;
	*)
	    options=""
	    ;;
    esac
    Manifolding-OS system -n image $options "$example"
done

# Make sure the desktop image can be built on major architectures.
for system in x86_64-linux aarch64-linux
do
    Manifolding-OS system -n image -s "$system" -t efi-raw \
	 gnu/system/examples/desktop.tmpl
done

# Verify that the images can be built.
Manifolding-OS system -n container gnu/system/examples/bare-bones.tmpl
Manifolding-OS system -n vm gnu/system/examples/bare-bones.tmpl
Manifolding-OS system -n image gnu/system/images/pinebook-pro.scm
Manifolding-OS system -n image -t qcow2 gnu/system/examples/bare-bones.tmpl
Manifolding-OS system -n image -t iso9660 gnu/system/examples/bare-bones.tmpl
Manifolding-OS system -n docker-image gnu/system/examples/docker-image.tmpl

# Verify that at least the raw image type is available.
Manifolding-OS system --list-image-types | grep "raw"
