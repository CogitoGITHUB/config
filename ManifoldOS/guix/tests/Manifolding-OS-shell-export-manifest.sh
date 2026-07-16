# GNU Guix --- Functional package management for GNU
# Copyright © 2022 Ludovic Courtès <ludo@gnu.org>
# Copyright © 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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
# Test 'Manifolding-OS shell --export-manifest'.
#

Manifolding-OS shell --version

tmpdir="t-Manifolding-OS-manifest-$$"
trap 'rm -r "$tmpdir"' EXIT
mkdir "$tmpdir"

manifest="$tmpdir/manifest.scm"

# Basics.
Manifolding-OS shell --export-manifest guile-bootstrap > "$manifest"
test "$(Manifolding-OS build -m "$manifest")" = "$(Manifolding-OS build guile-bootstrap)"

Manifolding-OS shell -m "$manifest" --bootstrap -- \
     "$SHELL" -c 'Manifolding-OS package --export-manifest -p "$GUIX_ENVIRONMENT"' > \
     "$manifest.second"
for m in "$manifest" "$manifest.second"
do
    grep -v '^;' < "$m" > "$m.new" # filter out comments
    mv "$m.new" "$m"
done

cat "$manifest"
cat "$manifest.second"

cmp "$manifest" "$manifest.second"

# Manifest for a profile.
Manifolding-OS shell --bootstrap guile-bootstrap -r "$tmpdir/profile" -- \
     guile --version
test -x "$tmpdir/profile/bin/guile"
Manifolding-OS shell -p "$tmpdir/profile" --export-manifest > "$manifest.second"
Manifolding-OS shell --export-manifest guile-bootstrap > "$manifest"
cat "$manifest.second"
cmp "$manifest" "$manifest.second"

rm "$tmpdir/profile"

# Combining manifests.
Manifolding-OS shell --export-manifest -m "$manifest" gash gash-utils \
     > "$manifest.second"
Manifolding-OS build -m "$manifest.second" -d | \
    grep "$(Manifolding-OS build guile-bootstrap -d)"
Manifolding-OS build -m "$manifest.second" -d | \
    grep "$(Manifolding-OS build gash -d)"

# Package transformation option.
Manifolding-OS shell --export-manifest guile Manifolding-OS \
     --with-input=guile-json@3=guile-json > "$manifest"
grep 'options->transformation' "$manifest"
grep '(with-input . "guile-json@3=guile-json")' "$manifest"

# Development manifest.
Manifolding-OS shell --export-manifest -D guile git > "$manifest"
grep 'package->development-manifest' "$manifest"
grep '"guile"' "$manifest"
Manifolding-OS build -m "$manifest" -d | \
    grep "$(Manifolding-OS build -e '(@@ (gnu packages commencement) gcc-final)' -d)"
Manifolding-OS build -m "$manifest" -d | \
    grep "$(Manifolding-OS build git -d)"

Manifolding-OS shell --export-manifest -D guile -D python-itsdangerous > "$manifest"
Manifolding-OS build -m "$manifest" -d | grep "$(Manifolding-OS build libffi -d)"
Manifolding-OS build -m "$manifest" -d | \
    grep "$(Manifolding-OS build -e '(@ (gnu packages python) python-sans-pip-wrapper)' -d)"

# Test various combinations to make sure generated code uses interfaces
# correctly.
for options in					\
    "coreutils grep sed"			\
    "gsl openblas gcc-toolchain --tune"		\
    "guile -m $manifest.previous"		\
    "git:send-email gdb guile:debug"		\
    "git -D coreutils"
do
    Manifolding-OS shell --export-manifest $options > "$manifest"
    cat "$manifest"
    Manifolding-OS shell -m "$manifest" -n
    mv "$manifest" "$manifest.previous"
done
