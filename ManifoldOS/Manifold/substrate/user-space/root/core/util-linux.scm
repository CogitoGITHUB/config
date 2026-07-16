(define-module (substrate user-space root core util-linux)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages linux)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:export (util-linux))

(define-public util-linux
  (package
    (name "util-linux")
    (version "2.40.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://www.kernel.org/pub/linux/utils/util-linux/v2.40/" name "-" version ".tar.xz"))
       (sha256
        (base32 "0vhxzhwr83vhbxqrgphai2ja76z9cajz1i7k2qqz30q0kq1ds6yh"))))
    (build-system gnu-build-system)
    (inputs (list ncurses libcap))
    (arguments
     '(#:configure-flags
       (list "--without-python"
              "--enable-write")))
    (home-page "https://www.kernel.org/pub/linux/utils/util-linux/")
    (synopsis "System utilities")
    (description "System utilities for Linux.")
    (license license:gpl2+)))
