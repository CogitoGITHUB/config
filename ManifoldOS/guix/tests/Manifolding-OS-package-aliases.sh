# GNU Guix --- Functional package management for GNU
# Copyright © 2019, 2020 Ludovic Courtès <ludo@gnu.org>
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
# Test the `Manifolding-OS package' aliases.
#

Manifolding-OS install --version

readlink_base ()
{
    basename `readlink "$1"`
}

profile="t-profile-$$"
rm -f "$profile"

trap 'rm -f "$profile" "$profile-"[0-9]*' EXIT

Manifolding-OS install --bootstrap guile-bootstrap -p "$profile"
test -x "$profile/bin/guile"

# Make sure '-r' isn't passed as-is to 'Manifolding-OS package'.
Manifolding-OS install -r guile-bootstrap -p "$profile" --bootstrap && false
test -x "$profile/bin/guile"

# Use a package transformation option and make sure it's recorded.
Manifolding-OS install --bootstrap guile-bootstrap -p "$profile" \
     --with-input=libreoffice=inkscape
test -x "$profile/bin/guile"
grep "libreoffice=inkscape" "$profile/manifest"

Manifolding-OS upgrade --version
Manifolding-OS upgrade -n
Manifolding-OS upgrade gui.e -n
Manifolding-OS upgrade foo bar -n

Manifolding-OS remove --version
Manifolding-OS remove --bootstrap guile-bootstrap -p "$profile"
test ! -x "$profile/bin/guile"
test `Manifolding-OS package -p "$profile" -I | wc -l` -eq 0

Manifolding-OS remove -p "$profile" this-is-not-installed --bootstrap && false

Manifolding-OS remove -i guile-bootstrap -p "$profile" --bootstrap && false

Manifolding-OS search '\<board\>' game | grep '^name: gnubg'

Manifolding-OS show --version
Manifolding-OS show guile
Manifolding-OS show python@3 | grep "^name: python"

# "python@2" exists but is deprecated; make sure it doesn't show up.
Manifolding-OS show python@2 && false

# Specifying multiple packages.
output="`Manifolding-OS show sed grep | grep ^name:`"
test "$output" = "name: sed
name: grep"
