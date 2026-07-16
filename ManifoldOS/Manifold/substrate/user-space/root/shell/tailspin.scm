(define-module (substrate user-space root shell tailspin)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (tailspin))

(define-public tailspin
  (package
    (name "tailspin")
    (version "6.1.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/bensadeh/tailspin/releases/"
                    "download/" version
                    "/tailspin-x86_64-unknown-linux-musl.tar.gz"))
              (sha256
               (base32
                "1jwbcrns4q2fiidzhbm5jjyma5pn3w9zdwzskw2456hblmgnkznv"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("tspin" "bin/tspin"))))
    (synopsis "Log file highlighter")
    (description
     "Tailspin (tspin) is a log file highlighter that reads any log file
and highlights dates, IP addresses, UUIDs, URLs, numbers, keywords, and
more with no configuration required.  It integrates with less as a pager
and supports stdin piping and custom themes.")
    (home-page "https://github.com/bensadeh/tailspin")
    (license license:expat)))
