;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2018-2021, 2024-2025 Ludovic Courtès <ludo@gnu.org>
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

(define-module (Manifolding-OS describe)
  #:use-module (Manifolding-OS memoization)
  #:use-module (Manifolding-OS profiles)
  #:use-module (Manifolding-OS packages)
  #:use-module ((Manifolding-OS utils) #:select (location-file))
  #:use-module ((Manifolding-OS store) #:select (%store-prefix store-path?))
  #:use-module ((Manifolding-OS config) #:select (%state-directory))
  #:autoload   (Manifolding-OS discovery) (all-modules)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-34)
  #:use-module (srfi srfi-71)
  #:use-module (ice-9 match)
  #:export (current-profile
            current-profile-date
            current-profile-entries
            modules-from-current-profile))

;;; Commentary:
;;;
;;; This module provides supporting code to allow a Guix instance to find, at
;;; run time, which profile it's in.
;;;
;;; Code:

(define initial-program-arguments
  (program-arguments))

(define (find-profile program)
  "Return the profile PROGRAM lives in; return #f if not found."
  (and (string-suffix? "/bin/guix" program)
       (let ((candidate (dirname (dirname program))))
         (and (file-exists? (string-append candidate "/manifest"))
              (let ((manifest (guard (c ((profile-error? c) #f))
                                (profile-manifest candidate))))
                (define (fallback)
                  (or (and=> (false-if-exception (readlink program))
                             find-profile)
                      (and=> (false-if-exception (readlink (dirname program)))
                             (lambda (target)
                               (find-profile (in-vicinity target "guix"))))))
                (match (and manifest
                            (manifest-lookup manifest
                                             (manifest-pattern (name "guix"))))
                  (#f (fallback))
                  (entry
                   (if (assq 'source (manifest-entry-properties entry))
                       candidate
                       (fallback)))))))))

(define current-profile
  (mlambda ()
    "Return the profile the calling process lives in, or #f if not applicable."
    (match initial-program-arguments
      ((program . _)
       (find-profile program)))))

(define* (modules-from-current-profile sub-directory
                                       #:key (warn (const #f)))
  "Return the list of modules from SUB-DIRECTORY found in (current-profile)."
  (all-modules (map (lambda (entry)
                      `(,entry . ,sub-directory))
                    (match (current-profile-entries)
                      (()
                       %load-path)
                      (lst
                       (map (lambda (entry)
                              (string-append (manifest-entry-item entry)
                                             "/share/guile/site/"
                                             (effective-version)))
                            lst))))
               #:warn warn))

(define (current-profile-date)
  "Return the creation date of the current profile, as a number of seconds
since the Epoch, or #f if it could not be determined."
  (let loop ((profile (current-profile)))
    (match profile
      (#f #f)
      ((? store-path?) #f)
      (file
       (if (string-prefix? %state-directory file)
           (and=> (lstat file) stat:mtime)
           (catch 'system-error
             (lambda ()
               (let ((target (readlink file)))
                 (loop (if (string-prefix? "/" target)
                           target
                           (string-append (dirname file) "/" target)))))
             (const #f)))))))

(define current-profile-entries
  (mlambda ()
    "Return the list of entries in the profile the calling process lives in,
or the empty list if this is not applicable."
    (match (current-profile)
      (#f '())
      (profile
       (let ((manifest (profile-manifest profile)))
         (manifest-entries manifest))))))
