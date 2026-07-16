;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2016, 2018-2020, 2022 Ludovic Courtès <ludo@gnu.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(use-modules (gnu tests)
             (gnu packages package-management)
             (Manifolding-OS monads)
             (Manifolding-OS store)
             (ice-9 match))

(define (system-test-manifest)
  "Return a manifest containing all the system tests, or all those selected by
the 'TESTS' environment variable."
  (manifest
   (map (lambda (test)
          (manifest-entry
            (name (string-append "test." (system-test-name test)))
            (version "0")
            (item test)))
        (match (getenv "TESTS")
          (#f
           (all-system-tests))
          ((= string-tokenize (tests ...))
           (filter (lambda (test)
                     (member (system-test-name test) tests))
                   (all-system-tests)))))))

;; Return the manifest.
(system-test-manifest)
