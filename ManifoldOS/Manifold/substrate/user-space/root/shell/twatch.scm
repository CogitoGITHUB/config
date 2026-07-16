(define-module (substrate user-space root shell twatch)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (twatch))

(define-public twatch
  (package
    (name "twatch")
    (version "0.1.5")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/blacknon/twatch/releases/"
                    "download/v" version
                    "/twatch-" version ".x86_64-unknown-linux-musl.tar.gz"))
              (sha256
               (base32
                "0hy0j5h2kxjvymifgl7wav215a0lgd3ky6ial3ml4d2xfbrlvwmh"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("twatch" "bin/"))))
    (synopsis "Record, rewind, inspect, and diff TUI apps")
    (description
     "twatch runs a child TUI app through a PTY, records its screen
states, and lets you rewind, search, and diff previous frames.
It can also extract selected ranges in batch mode.")
    (home-page "https://github.com/blacknon/twatch")
    (license license:expat)))
