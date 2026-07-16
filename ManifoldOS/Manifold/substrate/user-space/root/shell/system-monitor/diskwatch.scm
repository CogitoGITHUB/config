(define-module (substrate user-space root shell system-monitor diskwatch)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (diskwatch))

(define-public diskwatch
  (package
    (name "diskwatch")
    (version "0.1.2")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/matthart1983/diskwatch/releases/"
                    "download/v" version
                    "/diskwatch-linux-x86_64-static.tar.gz"))
              (sha256
               (base32
                "0fizh5whrskd2xwynnmff72kg80pk5bikv7pdz7x95q5hjw3bpfw"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("diskwatch-linux-x86_64-static" "bin/diskwatch"))))
    (synopsis "Single-host disk diagnostics TUI")
    (description
     "DiskWatch is a TUI for disk diagnostics with eight tabs: Overview,
Devices, Volumes, FS, IO, SMART, Hot Files, and Insights.  It shows
capacity, throughput, p99 latency, SMART health, and the files being
written right now.  Sibling to NetWatch and SysWatch.")
    (home-page "https://github.com/matthart1983/diskwatch")
    (license license:expat)))
