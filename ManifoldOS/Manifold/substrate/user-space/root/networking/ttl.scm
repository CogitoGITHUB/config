;; ttl — traceroute/path analysis TUI
;; Designed to complement netwatch: ttl handles deep path analysis
;; (ASN/GeoIP, MPLS, MTU, ECMP, NAT detection, route flaps) while
;; netwatch provides a broad network diagnostics dashboard
;; (connections, interfaces, packets, TLS decryption, C2 detection).
;; Install both for full network visibility.

(define-module (substrate user-space root networking ttl)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (ttl))

(define-public ttl
  (package
    (name "ttl")
    (version "0.20.1")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/lance0/ttl/releases/download/v" version
              "/ttl-x86_64-unknown-linux-musl.tar.gz"))
        (sha256 (base32 "15p2nqpp7ppm9fnhr2w31a7vg7h94q98x3mx1nqpq3lixzfv70n4"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan '(("ttl" "bin/"))))
    (native-inputs (list gzip))
    (home-page "https://github.com/lance0/ttl")
    (synopsis "Fast traceroute with real-time TUI, ASN/GeoIP, ECMP, MPLS")
    (description
     "TTL is a network diagnostic tool that goes beyond traceroute: MTU
discovery, NAT detection, route flap alerts, IX identification, MPLS label
parsing, and more.  Designed to complement netwatch — use ttl for deep path
analysis and netwatch for broad network diagnostics.")
    (license license:expat)))
