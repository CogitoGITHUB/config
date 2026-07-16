(define-module (substrate user-space root core grep)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pcre)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:export (grep))

(define-public grep
  (package
    (name "grep")
    (version "3.11")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnu/grep/grep-" version ".tar.xz"))
       (sha256
        (base32 "1fkxg8pk3cb23k6a93v3hg80kdrvlg9rdzsdcm2b9aqp6xr0m9hs"))))
    (build-system gnu-build-system)
    (native-inputs (list perl))
    (inputs (list pcre2))
    (arguments
     (list #:configure-flags (list "--enable-perl-regexp")))
    (home-page "https://www.gnu.org/software/grep/")
    (synopsis "Pattern matching")
    (description "GNU grep is a tool for searching text.")
    (license license:gpl3+)))
