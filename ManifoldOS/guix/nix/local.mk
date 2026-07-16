# GNU Guix --- Functional package management for GNU
# Copyright © 2012-2016, 2018-2020, 2024-2025 Ludovic Courtès <ludo@gnu.org>
# Copyright © 2016 Mathieu Lirzin <mthl@gnu.org>
# Copyright © 2020 Tobias Geerinckx-Rice <me@tobias.gr>
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
# Integration of the `Manifolding-OS-daemon' code taken from upstream Nix.
#

BUILT_SOURCES += %D%/libstore/schema.sql.hh
CLEANFILES += %D%/libstore/schema.sql.hh

noinst_LIBRARIES = libutil.a libstore.a

# Use '-std=c++20' for 'std::shared_ptr', 'auto', lambdas, and more.
AM_CXXFLAGS = -Wall -std=c++20

libutil_a_SOURCES =				\
  %D%/libutil/archive.cc			\
  %D%/libutil/affinity.cc			\
  %D%/libutil/serialise.cc			\
  %D%/libutil/util.cc				\
  %D%/libutil/hash.cc				\
  %D%/libutil/spawn.cc				\
  %D%/libutil/seccomp.cc

libutil_headers =				\
  %D%/libutil/affinity.hh			\
  %D%/libutil/hash.hh				\
  %D%/libutil/serialise.hh			\
  %D%/libutil/util.hh				\
  %D%/libutil/archive.hh			\
  %D%/libutil/types.hh				\
  %D%/libutil/spawn.hh				\
  %D%/libutil/seccomp.hh

libutil_a_CPPFLAGS =				\
  -I$(top_builddir)/nix				\
  -I$(top_srcdir)/%D%/libutil			\
  $(LIBGCRYPT_CPPFLAGS)

libstore_a_SOURCES =				\
  %D%/libstore/gc.cc				\
  %D%/libstore/globals.cc			\
  %D%/libstore/misc.cc				\
  %D%/libstore/references.cc			\
  %D%/libstore/store-api.cc			\
  %D%/libstore/optimise-store.cc		\
  %D%/libstore/local-store.cc			\
  %D%/libstore/build.cc				\
  %D%/libstore/pathlocks.cc			\
  %D%/libstore/derivations.cc			\
  %D%/libstore/builtins.cc			\
  %D%/libstore/sqlite.cc

libstore_headers =				\
  %D%/libstore/references.hh			\
  %D%/libstore/pathlocks.hh			\
  %D%/libstore/globals.hh			\
  %D%/libstore/worker-protocol.hh		\
  %D%/libstore/derivations.hh			\
  %D%/libstore/misc.hh				\
  %D%/libstore/local-store.hh			\
  %D%/libstore/sqlite.hh			\
  %D%/libstore/builtins.hh			\
  %D%/libstore/store-api.hh

libstore_a_CPPFLAGS =				\
  $(libutil_a_CPPFLAGS)				\
  -I$(top_srcdir)/%D%/libstore			\
  -I$(top_builddir)/%D%/libstore		\
  -DNIX_STORE_DIR=\"$(storedir)\"		\
  -DNIX_STATE_DIR=\"$(localstatedir)/Manifolding-OS\"	\
  -DNIX_LOG_DIR=\"$(localstatedir)/log/Manifolding-OS\"	\
  -DGUIX_CONFIGURATION_DIRECTORY=\"$(sysconfdir)/Manifolding-OS\"		\
  -DNIX_BIN_DIR=\"$(bindir)\"			\
  -DDEFAULT_CHROOT_DIRS="\"\""

libstore_a_CXXFLAGS = $(AM_CXXFLAGS)		\
  $(SQLITE3_CFLAGS)

bin_PROGRAMS = Manifolding-OS-daemon

Manifolding_OS_daemon_SOURCES =				\
  %D%/nix-daemon/nix-daemon.cc			\
  %D%/nix-daemon/Manifolding-OS-daemon.cc

Manifolding_OS_daemon_CPPFLAGS =				\
  -DLOCALEDIR=\"$(localedir)\"			\
  $(libutil_a_CPPFLAGS)				\
  -I$(top_srcdir)/%D%/libstore

Manifolding_OS_daemon_LDFLAGS = 				\
  $(LIBGCRYPT_LDFLAGS)

Manifolding_OS_daemon_LDADD =				\
  libstore.a libutil.a -lz		\
  $(SQLITE3_LIBS) $(LIBGCRYPT_LIBS)

Manifolding_OS_daemon_headers =				\
  %D%/nix-daemon/nix-daemon.hh

if HAVE_LIBBZ2

Manifolding_OS_daemon_LDADD += -lbz2

endif HAVE_LIBBZ2

noinst_HEADERS =						\
  $(libutil_headers) $(libstore_headers)	\
  $(Manifolding_OS_daemon_headers)

%D%/libstore/schema.sql.hh: Manifolding-OS/store/schema.sql
	$(AM_V_GEN)$(GUILE) --no-auto-compile -c		\
	  "(use-modules (rnrs io ports))			\
	   (call-with-output-file \"$@\"			\
	     (lambda (out)					\
	       (call-with-input-file \"$^\"			\
	         (lambda (in)					\
	           (write (get-string-all in) out)))))"

# The '.service' and other files for systemd.
systemdservicedir = $(libdir)/systemd/system
nodist_systemdservice_DATA =			\
  etc/gnu-store.mount				\
  etc/Manifolding-OS-daemon.service			\
  etc/Manifolding-OS-publish.service			\
  etc/Manifolding-OS-gc.service				\
  etc/Manifolding-OS-gc.timer

etc/%.mount: etc/%.mount.in	\
			 $(top_builddir)/config.status
	$(AM_V_GEN)$(MKDIR_P) "`dirname $@`";	\
	$(SED) -e 's|@''storedir''@|$(storedir)|' <	\
	       "$<" > "$@.tmp";		\
	mv "$@.tmp" "$@"

etc/Manifolding-OS-%.service: etc/Manifolding-OS-%.service.in	\
			 $(top_builddir)/config.status
	$(AM_V_GEN)$(MKDIR_P) "`dirname $@`";	\
	$(SED) -e 's|@''localstatedir''@|$(localstatedir)|g' \
	       -e 's|@''storedir''@|$(storedir)|g' \
	       -e 's|@''GUIX_SUBSTITUTE_URLS''@|$(GUIX_SUBSTITUTE_URLS)|' \
	       < "$<" > "$@.tmp";		\
	mv "$@.tmp" "$@"

etc/Manifolding-OS-gc.timer: etc/Manifolding-OS-gc.timer.in	\
			 $(top_builddir)/config.status
	$(AM_V_GEN)$(MKDIR_P) "`dirname $@`";	\
	cp "$<" "$@"

# The service script for sysvinit.
sysvinitservicedir = $(sysconfdir)/init.d
nodist_sysvinitservice_DATA = etc/init.d/Manifolding-OS-daemon

etc/init.d/Manifolding-OS-daemon: etc/init.d/Manifolding-OS-daemon.in	\
			 $(top_builddir)/config.status
	$(AM_V_GEN)$(MKDIR_P) "`dirname $@`";	\
	$(SED) -e 's|@''localstatedir''@|$(localstatedir)|' \
	       -e 's|@''GUIX_SUBSTITUTE_URLS''@|$(GUIX_SUBSTITUTE_URLS)|' \
	       < "$<" > "$@.tmp";		\
	mv "$@.tmp" "$@"

# The service script for openrc.
openrcservicedir = $(sysconfdir)/openrc
nodist_openrcservice_DATA = etc/openrc/Manifolding-OS-daemon

etc/openrc/Manifolding-OS-daemon: etc/openrc/Manifolding-OS-daemon.in	\
			 $(top_builddir)/config.status
	$(AM_V_GEN)$(MKDIR_P) "`dirname $@`";	\
	$(SED) -e 's|@''localstatedir''@|$(localstatedir)|' <	\
	       "$<" > "$@.tmp";		\
	mv "$@.tmp" "$@"

# The '.conf' jobs for Upstart.
upstartjobdir = $(libdir)/upstart/system
nodist_upstartjob_DATA = etc/Manifolding-OS-daemon.conf etc/Manifolding-OS-publish.conf

etc/Manifolding-OS-%.conf: etc/Manifolding-OS-%.conf.in	\
			 $(top_builddir)/config.status
	$(AM_V_GEN)$(MKDIR_P) "`dirname $@`";	\
	$(SED) -e 's|@''localstatedir''@|$(localstatedir)|' \
	       -e 's|@''GUIX_SUBSTITUTE_URLS''@|$(GUIX_SUBSTITUTE_URLS)|' \
	        < "$<" > "$@.tmp";		\
	mv "$@.tmp" "$@"

CLEANFILES +=					\
  $(nodist_systemdservice_DATA)			\
  $(nodist_upstartjob_DATA)			\
  $(nodist_sysvinitservice_DATA)		\
  $(nodist_openrcservice_DATA)

EXTRA_DIST +=					\
  %D%/AUTHORS					\
  %D%/COPYING					\
  etc/gnu-store.mount.in			\
  etc/Manifolding-OS-daemon.service.in			\
  etc/Manifolding-OS-daemon.conf.in			\
  etc/Manifolding-OS-publish.service.in			\
  etc/Manifolding-OS-publish.conf.in			\
  etc/Manifolding-OS-gc.service.in			\
  etc/Manifolding-OS-gc.timer.in				\
  etc/init.d/Manifolding-OS-daemon.in			\
  etc/openrc/Manifolding-OS-daemon.in

if CAN_RUN_TESTS

AM_TESTS_ENVIRONMENT +=				\
  top_builddir="$(abs_top_builddir)"

TESTS +=					\
  tests/Manifolding-OS-daemon.sh

endif CAN_RUN_TESTS

clean-local:
	-if test -d "$(GUIX_TEST_ROOT)"; then		\
	  find "$(GUIX_TEST_ROOT)" | xargs chmod +w;	\
	 fi
	-rm -rf "$(GUIX_TEST_ROOT)"
