# GNU Guix --- Functional package management for GNU
# Copyright © 2018, 2019, 2020, 2022 Ludovic Courtès <ludo@gnu.org>
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
# Test 'Manifolding-OS build --with-branch'.
#

Manifolding-OS build --version

# 'Manifolding-OS build --with-branch' requires access to the network to clone the
# Git repository below.

if ! guile -c '(getaddrinfo "www.gnu.org" "80" AI_NUMERICSERV)' 2> /dev/null
then
    # Skipping.
    exit 77
fi

orig_drv="`Manifolding-OS build guile-gcrypt -d`"
latest_drv="`Manifolding-OS build guile-gcrypt --with-branch=guile-gcrypt=main -d`"
test -n "$latest_drv"
test "$orig_drv" != "$latest_drv"

# FIXME: '-S' currently doesn't work with non-derivation source.
# checkout="`Manifolding-OS build guile-gcrypt --with-branch=guile-gcrypt=main -S`"
checkout="`Manifolding-OS gc --references "$latest_drv" | grep guile-gcrypt | grep -v -E '(-builder|\.drv)'`"
test -d "$checkout"
test -f "$checkout/COPYING"

orig_drv="`Manifolding-OS build Manifolding-OS -d`"
latest_drv="`Manifolding-OS build Manifolding-OS --with-branch=guile-gcrypt=main -d`"
Manifolding-OS gc -R "$latest_drv" | grep guile-gcrypt-git.main
test "$orig_drv" != "$latest_drv"

v0_1_0_drv="`Manifolding-OS build Manifolding-OS --with-commit=guile-gcrypt=9e3eacdec1d -d`"
Manifolding-OS gc -R "$v0_1_0_drv" | grep guile-gcrypt-git.9e3eacd
test "$v0_1_0_drv" != "$latest_drv"
test "$v0_1_0_drv" != "$orig_drv"

v0_1_0_drv="`Manifolding-OS build Manifolding-OS --with-commit=guile-gcrypt=v0.1.0 -d`"
Manifolding-OS gc -R "$v0_1_0_drv" | grep guile-gcrypt-0.1.0
Manifolding-OS gc -R "$v0_1_0_drv" | grep guile-gcrypt-9e3eacd
test "$v0_1_0_drv" != "$latest_drv"
test "$v0_1_0_drv" != "$orig_drv"

Manifolding-OS build Manifolding-OS --with-commit=guile-gcrypt=000 -d && false

exit 0
