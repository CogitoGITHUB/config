(define-module (substrate user-space root networking curl)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages tls)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (substrate user-space root shell archive zlib)
  #:export (curl))

(define-public curl
  (package
    (name "curl")
    (version "8.6.0")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "https://curl.se/download/curl-" version ".tar.xz"))
        (sha256
          (base32 "05fv468yjrb7qwrxmfprxkrcckbkij0myql0vwwnalgr3bcmbk9w"))))
    (build-system gnu-build-system)
    (inputs (list gnutls zlib))
    (arguments '(#:tests? #f))
    (home-page "https://curl.se/")
    (synopsis "Command line tool for transferring data with URL syntax")
    (description "Curl is a command line tool for transferring data with URL syntax.")
    (license license:expat)))
