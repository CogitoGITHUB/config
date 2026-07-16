# GNU Guix --- Functional package management for GNU
# Copyright © 2018, 2019 Ludovic Courtès <ludo@gnu.org>
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
# Test the 'Manifolding-OS pack --localstatedir' command-line utility.
#

Manifolding-OS pack --version

# 'Manifolding-OS pack --localstatedir' produces derivations that depend on
# guile-sqlite3 and guile-gcrypt.  To make that relatively inexpensive, run
# the test in the user's global store if possible, on the grounds that
# binaries may already be there or can be built or downloaded inexpensively.

storedir="`guile -c '(use-modules (Manifolding-OS config))(display %storedir)'`"
localstatedir="`guile -c '(use-modules (Manifolding-OS config))(display %localstatedir)'`"
NIX_STORE_DIR="$storedir"
GUIX_DAEMON_SOCKET="$localstatedir/Manifolding-OS/daemon-socket/socket"
GUIX_BUILD_OPTIONS="--timeout=`guile -c '(use-modules (Manifolding-OS tests))(display %tests-build-timeout)'`"
export NIX_STORE_DIR GUIX_DAEMON_SOCKET GUIX_BUILD_OPTIONS

if ! guile -c '(use-modules (Manifolding-OS)) (exit (false-if-exception (open-connection)))'
then
    exit 77
fi

# Build a tarball with '--localstatedir'
the_pack="`Manifolding-OS pack -C none --localstatedir --profile-name=current-Manifolding-OS \
            guile-bootstrap`"
test_directory="`mktemp -d`"
trap 'chmod -Rf +w "$test_directory"; rm -rf "$test_directory"' EXIT

cd "$test_directory"
tar -xf "$the_pack"

profile="`find -name current-Manifolding-OS`"
test "`readlink $profile`" = "current-Manifolding-OS-1-link"
test -s "`dirname $profile`/../../../db/db.sqlite"
test -x ".`Manifolding-OS build guile-bootstrap`/bin/guile"
cd -

# Make sure the store database is not completely bogus.
guile -c "(use-modules (sqlite3) (Manifolding-OS config) (ice-9 match))

  (define db
    (sqlite-open (string-append \"$test_directory\"
                                %localstatedir
                               \"/Manifolding-OS/db/db.sqlite\")
                 SQLITE_OPEN_READONLY))

  (define stmt
    (sqlite-prepare db \"SELECT * FROM ValidPaths;\"))

  (match (sqlite-fold cons '() stmt)
    ((#(ids paths hashes times derivers sizes) ...)
     (exit (member \"`Manifolding-OS build guile-bootstrap`\" paths))))"
