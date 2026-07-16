(define-module (substrate user-space root networking surge)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (surge))

(define-public surge
  (package
    (name "surge")
    (version "0.10.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/SurgeDM/Surge/releases/"
                    "download/v" version
                    "/Surge_" version "_linux_amd64.tar.gz"))
              (sha256
               (base32
                "1py4rbzxm9vdn39fh3f8lpwy9cp87kfcm7s2pls4f6v8m7va4ksz"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("surge" "bin/surge"))))
    (synopsis "Blazing fast TUI download manager")
    (description
     "Surge is a terminal download manager with an interactive TUI
supporting multi-connection downloads, pause/resume, download queue,
batch downloads, real-time progress graphs, headless server mode, and
a browser extension.")
    (home-page "https://github.com/SurgeDM/Surge")
    (license license:expat)))
