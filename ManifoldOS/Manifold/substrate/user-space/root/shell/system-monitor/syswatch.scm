(define-module (substrate user-space root shell system-monitor syswatch)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (syswatch))

(define-public syswatch
  (package
    (name "syswatch")
    (version "0.7.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/matthart1983/syswatch/releases/"
                    "download/v" version
                    "/syswatch-linux-x86_64-static.tar.gz"))
              (sha256
               (base32
                "1mbz55mzgknx4fz7xgn3psc69y0x2cxlc3hyiq184malk7wiimnl"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("syswatch-linux-x86_64-static" "bin/syswatch"))))
    (synopsis "Single-host system diagnostics TUI")
    (description
     "SysWatch is a single-host system diagnostics TUI showing CPU,
memory, processes, units, temperature, sensors, and insights.
Sibling to NetWatch and DiskWatch.")
    (home-page "https://github.com/matthart1983/syswatch")
    (license license:expat)))
