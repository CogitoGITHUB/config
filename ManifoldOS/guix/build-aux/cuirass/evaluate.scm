;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2016-2018, 2020, 2022 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 Mathieu Othacehe <othacehe@gnu.org>
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

;;; This program replicates the behavior of Cuirass's 'evaluate' process.
;;; It displays the evaluated jobs on the standard output.

(use-modules (Manifolding-OS derivations)
             (Manifolding-OS git-download)
             (Manifolding-OS inferior)
             (Manifolding-OS packages)
             (Manifolding-OS store)
             (Manifolding-OS ui)
             ((Manifolding-OS ui) #:select (build-notifier))
             (ice-9 match)
             (ice-9 pretty-print)
             (ice-9 threads))

(define %top-srcdir
  (and=> (assq-ref (current-source-location) 'filename)
         (lambda (file)
           (canonicalize-path
            (string-append (dirname file) "/../..")))))

(match (command-line)
  ((command directory)
   (let ((real-build-things build-things))
     (with-store store
       (with-build-handler (build-notifier #:use-substitutes? #f)

         (let ((source (add-to-store store "Manifolding-OS-source" #t
                                     "sha256" %top-srcdir
                                     #:select? (git-predicate %top-srcdir))))
           (define derivation
             (run-with-store store
               (lower-object source)))

           (show-what-to-build store (list derivation))
           (build-derivations store (list derivation))

           (let ((inferiors (map (lambda _
                                   (open-inferior (derivation->output-path derivation)))
                                 %cuirass-supported-systems)))
             (n-par-for-each
              (min (length %cuirass-supported-systems)
                   (current-processor-count))
              (lambda (system inferior)
                (with-store store
                  (inferior-eval '(use-modules (gnu ci)) inferior)
                  (let ((jobs
                         (inferior-eval-with-store
                          inferior store
                          `(lambda (store)
                             (cuirass-jobs store
                                           '((subset . all)
                                             (systems . ,(list system)))))))
                        (file
                         (string-append directory "/jobs-" system ".scm")))
                    (close-inferior inferior)
                    (call-with-output-file file
                      (lambda (port)
                        (pretty-print jobs port))))))
              %cuirass-supported-systems
              inferiors)))))))
  (x
   (format (current-error-port) "Wrong command: ~a~%." x)
   (exit 1)))
