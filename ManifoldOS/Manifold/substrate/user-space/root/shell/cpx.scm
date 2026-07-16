(define-module (substrate user-space root shell cpx)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (cpx))

(define-public cpx
  (package
    (name "cpx")
    (version "0.1.4")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/11happy/cpx/releases/download/v" version
              "/cpx-linux-x86_64-musl.tar.gz"))
        (sha256 (base32 "1h9mzx1sfbd2gfwv421j5bc2mvx941d7dpzzvqc43ia0clqahypr"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan '(("cpx" "bin/"))))
    (native-inputs (list gzip))
    (home-page "https://github.com/11happy/cpx")
    (synopsis "Modern file copying tool with progress bars")
    (description
     "cpx is a modern replacement for the @command{cp} command.  It provides
progress bars, recursive copying, and preserves file attributes.")
    (license license:expat)))
