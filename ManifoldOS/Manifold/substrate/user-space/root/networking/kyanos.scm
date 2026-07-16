(define-module (substrate user-space root networking kyanos)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (kyanos))

(define-public kyanos
  (package
    (name "kyanos")
    (version "1.6.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/hengyoush/kyanos/releases/"
                    "download/v" version
                    "/kyanos_" version "_linux_amd64.tar.gz"))
              (sha256
               (base32
                "1nxdgpx86y9cz0rllzbqvpsphkxdaal059v5afzp1sd0fawhgpv6"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("kyanos" "bin/kyanos"))))
    (synopsis "eBPF-based network issue analysis tool")
    (description
     "Kyanos is an eBPF-based networking analysis tool that captures
network requests (HTTP, Redis, MySQL, Kafka, MongoDB, RocketMQ, DNS),
visualizes kernel-level latency details, and filters traffic by process,
container, protocol, latency, and more.")
    (home-page "https://github.com/hengyoush/kyanos")
    (license license:asl2.0)))
