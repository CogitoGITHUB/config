(define-module (substrate user-space root shell superfile)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base)
  #:use-module (substrate user-space root shell archive unzip)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (superfile))

(define-public superfile
  (package
    (name "superfile")
    (version "1.6.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/yorukot/superfile/releases/download/v" version
                    "/superfile-linux-v" version "-amd64.tar.gz"))
              (sha256 (base32 "02d3vpircm21w4dzjzp6c64akmwwrbnlxa43g6maca960yahwnyl"))))
    (build-system trivial-build-system)
    (arguments
     '(#:modules ((guix build utils) (srfi srfi-1) (srfi srfi-26))
       #:builder
       (begin
         (use-modules (guix build utils) (srfi srfi-1) (srfi srfi-26))
         (let ((out (assoc-ref %outputs "out"))
               (src (assoc-ref %build-inputs "source"))
               (tar (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
               (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin/gzip"))
               (tools (string-append (assoc-ref %build-inputs "tar") "/bin:"
                                     (assoc-ref %build-inputs "gzip") "/bin")))
           (setenv "PATH" (string-append tools ":" (getenv "PATH")))
           (mkdir-p out)
           (invoke tar "-xzf" src "-C" out)
           (let ((dist-dir (string-append out "/dist")))
             (for-each
               (lambda (f)
                 (format #t "file: ~a~%" f)
                 (when (string-suffix? "/spf" f)
                   (let* ((bin-path (string-append out "/bin"))
                          (src-file f)
                          (dst-file (string-append bin-path "/superfile")))
                     (mkdir-p bin-path)
                     (copy-file src-file dst-file)
                     (chmod dst-file #o755))))
               (find-files dist-dir))
             (delete-file-recursively dist-dir))))))
    (inputs (list tar gzip))
    (home-page "https://github.com/yorukot/superfile")
    (synopsis "Modern terminal file manager")
    (description "Modern terminal file manager")
    (license license:expat)))
