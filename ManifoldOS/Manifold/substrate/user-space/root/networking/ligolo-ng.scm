(define-module (substrate user-space root networking ligolo-ng)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (ligolo-agent ligolo-proxy))

(define-public ligolo-agent
  (package
    (name "ligolo-agent")
    (version "0.8.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/nicocha30/ligolo-ng/releases/"
                    "download/v" version
                    "/ligolo-ng_agent_" version "_linux_amd64.tar.gz"))
              (sha256
               (base32
                "19ndcyjddxy4l22l2zdx8cxshfib56bvlcz6rgnvrchl7zjrzqy1"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("agent" "bin/ligolo-agent"))))
    (synopsis "Ligolo-ng agent")
    (description
     "Ligolo-ng agent component for establishing reverse TCP/TLS tunnels
without requiring administrative privileges.")
    (home-page "https://github.com/nicocha30/ligolo-ng")
    (license license:gpl3)))

(define-public ligolo-proxy
  (package
    (name "ligolo-proxy")
    (version "0.8.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/nicocha30/ligolo-ng/releases/"
                    "download/v" version
                    "/ligolo-ng_proxy_" version "_linux_amd64.tar.gz"))
              (sha256
               (base32
                "13hdiilxyv4yswg0vzjnajmfgjp14pfpg3yllj74wwd8rcsd4zm0"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("proxy" "bin/ligolo-proxy"))))
    (synopsis "Ligolo-ng proxy/relay server")
    (description
     "Ligolo-ng proxy/relay server component that creates a TUN interface
and manages tunnels from agent connections.")
    (home-page "https://github.com/nicocha30/ligolo-ng")
    (license license:gpl3)))
