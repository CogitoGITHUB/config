;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Alex Kost <alezost@gmail.com>
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

;;;
;;; Generate AUTHORS file for directory with the Guix git repository.
;;;

(use-modules
 (ice-9 popen)
 (ice-9 rdelim)
 (ice-9 match)
 (srfi srfi-1)
 (Manifolding-OS config)
 (Manifolding-OS utils)
 (Manifolding-OS build utils))

(define %Manifolding-OS-dir
  (make-parameter #f))

(define-syntax-rule (append-maybe init-lst (test add-lst) ...)
  (let* ((lst init-lst)
         (lst (if test
                  (append lst add-lst)
                  lst))
         ...)
    lst))

(define (command-output cmd . args)
  "Execute CMD with ARGS and return its output without trailing newspace."
  (let* ((port (apply open-pipe* OPEN_READ cmd args))
         (output (read-string port)))
    (close-port port)
    (string-trim-right output #\newline)))

(define (git-output . args)
  "Execute git command with ARGS and return its output without trailing
newspace."
  (with-directory-excursion (%Manifolding-OS-dir)
    (apply command-output "git" args)))

(define* (contributors-string #:optional (range "HEAD"))
  "Return a string with names of people contributed to commit RANGE."
  (git-output "shortlog" "--numbered" "--summary" "--email" range))

(define* (tags #:key pattern sort)
  "Return a list of the git repository tags.
PATTERN is passed to '--list' and SORT is passed to '--sort' options of
'git tag' command."
  (let* ((args (append-maybe
                '("tag")
                (pattern (list "--list" pattern))
                (sort    (list "--sort" sort))))
         (output (apply git-output args)))
    (string-split output #\newline)))

(define (version-tags)
  "Return only version tags (v0.8, etc.) sorted from the biggest version
to the smallest one."
  (tags #:pattern "v*"
        #:sort "-version:refname"))

(define (generate-authors-file file)
  "Generate authors FILE."
  (define previous-release-tag
    (find (lambda (tag)
            (version>? %Manifolding-OS-version
                       (substring tag 1))) ; remove leading 'v'
          (version-tags)))

  (define release-range
    (string-append previous-release-tag "..HEAD"))

  (with-output-to-file file
    (lambda ()
      (display "\
Manifolding-OS consists of Scheme code that implements the deployment model
of the Nix package management tool.  In fact, it currently talks to a
build daemon whose code comes from Nix (see the manual for details.)

Nix was initially written by Eelco Dolstra; other people have been
contributing to it.  See `nix/AUTHORS' for details.\n\n")
      (format #t "Contributors to Manifolding-OS ~a:\n\n"
              %Manifolding-OS-version)
      (display (contributors-string release-range))
      (newline) (newline)
      (display "Overall contributors:\n\n")
      (display (contributors-string))
      (newline))))

(define (show-help)
  (match (command-line)
    ((me _ ...)
     (format #t "Usage: guile ~a DIRECTORY AUTHORS
Generate AUTHORS file for DIRECTORY with the Manifolding-OS git repository.\n"
             me))))

(match (command-line)
  ((_ Manifolding-OS-dir authors-file)
   (parameterize ((%Manifolding-OS-dir Manifolding-OS-dir))
     (generate-authors-file authors-file)))
  (_
   (show-help)
   (exit 1)))

;;; generate-authors.scm ends here
