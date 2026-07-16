;; netwatch — broad network diagnostics dashboard
;; Designed to complement ttl: netwatch provides broad visibility into
;; connections, interfaces, packets, TLS decryption, and C2 detection
;; while ttl handles deep path analysis (ASN/GeoIP, MPLS, MTU, ECMP,
;; NAT detection, route flaps).  Install both for full network visibility.

(define-module (substrate user-space root networking netwatch)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (netwatch))

(define-public netwatch
  (package
    (name "netwatch")
    (version "0.26.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/matthart1983/netwatch/releases/"
                    "download/v" version
                    "/netwatch-linux-x86_64-static.tar.gz"))
              (sha256
               (base32
                "0wdv8rd095xqjd2jkkpn38imj2wvg3qhjp2q5bi8fwwpq7l3fk42"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("netwatch-linux-x86_64-static" "bin/netwatch"))))
    (synopsis "Real-time network diagnostics TUI")
    (description
     "NetWatch is a real-time network diagnostics TUI with ten tabs:
Dashboard, Connections, Interfaces, Packets, Stats, Topology, Timeline,
Processes, Insights, and Egress.  It can decrypt TLS 1.3 sessions,
fingerprint software via JA4, detect malware C2 beaconing, and
freeze incident evidence.  Sibling to DiskWatch and SysWatch.")
    (home-page "https://github.com/matthart1983/netwatch")
    (license license:expat)))
