# GNU Guix --- Functional package management for GNU
# Copyright © 2013, 2015, 2017, 2018, 2019 Ludovic Courtès <ludo@gnu.org>
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
# Test the `Manifolding-OS gc' command-line utility.
#

Manifolding-OS gc --version

trap "rm -f Manifolding-OS-gc-root" EXIT
rm -f Manifolding-OS-gc-root

# Below we are using 'drv' and 'out' to contain store file names.  If 'drv'
# and 'out' are environment variables, 'list-runtime-roots' will "see" them
# and thus prevent $drv and $out from being garbage-collected.  Using 'unset'
# allows us to make sure these are truly local shell variables and not
# environments variables.
unset drv
unset out

# For some operations, passing extra arguments is an error.
for option in "" "-C 500M" "--verify" "--optimize" "--list-roots"
do
    Manifolding-OS gc $option whatever && false
done

# This should fail.
Manifolding-OS gc --verify=foo && false

# Check the references of a .drv.
drv="`Manifolding-OS build guile-bootstrap -d`"
out="`Manifolding-OS build guile-bootstrap`"
test -f "$drv" && test -d "$out"

Manifolding-OS gc --references "$drv" | grep -e -bash
Manifolding-OS gc --references "$out"
Manifolding-OS gc --references "$out/bin/guile"

Manifolding-OS gc --references /dev/null && false

# Check derivers.
Manifolding-OS gc --derivers "$out" | grep "$drv"

# Add then reclaim a .drv file.
drv="`Manifolding-OS build idutils -d`"
test -f "$drv"

Manifolding-OS gc --list-dead | grep "$drv"
Manifolding-OS gc --delete "$drv"
test ! -f "$drv"

# Add a .drv, register it as a root.
drv="`Manifolding-OS build --root=Manifolding-OS-gc-root hello -d`"
test -f "$drv" && test -L Manifolding-OS-gc-root

Manifolding-OS gc --list-roots | grep "$PWD/Manifolding-OS-gc-root"

Manifolding-OS gc --list-live | grep "$drv"
Manifolding-OS gc --delete "$drv" && false

rm Manifolding-OS-gc-root
Manifolding-OS gc --list-dead | grep "$drv"
Manifolding-OS gc --delete "$drv"
test ! -f "$drv"

# Try a random collection.
Manifolding-OS gc -C 1KiB

# Check trivial error cases.
Manifolding-OS gc --delete /dev/null && false

# Bug #19757
out="`Manifolding-OS build guile-bootstrap`"
test -d "$out"

Manifolding-OS gc --delete "$out"

test ! -d "$out"

out="`Manifolding-OS build guile-bootstrap`"
test -d "$out"

Manifolding-OS gc --delete "$out/"

test ! -d "$out"

out="`Manifolding-OS build guile-bootstrap`"
test -d "$out"

Manifolding-OS gc --delete "$out/bin/guile"
