(define-module (substrate user-space root core coreutils)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:export (coreutils))

(define-public coreutils
  (package
    (name "coreutils")
    (version "9.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnu/coreutils/coreutils-" version ".tar.xz"))
       (sha256
        (base32 "08q4b0w7mwfxbqjs712l6wrwl2ijs7k50kssgbryg9wbsw8g98b1"))))
    (build-system gnu-build-system)
    (arguments
     `(#:parallel-build? #f
       #:phases
       (modify-phases %standard-phases
         (add-before 'build 'patch-shell-references
           (lambda _
             (setenv "SHELL" (which "sh"))
             (substitute* (find-files "gnulib-tests" "\\.c$")
               (("/bin/sh") (which "sh")))
             (substitute* (find-files "tests" "\\.sh$")
               (("#!/bin/sh") (string-append "#!" (which "sh")))))))))
    (home-page "https://www.gnu.org/software/coreutils/")
    (synopsis "Core GNU utilities")
    (description "The GNU Core Utilities, the basic file, shell and text manipulation utilities.")
    (license license:gpl3+)))
