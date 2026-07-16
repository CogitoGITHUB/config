(define-module (substrate user-space root security sliver)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (sliver-client sliver-server))

(define-public sliver-client
  (package
    (name "sliver-client")
    (version "1.7.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/BishopFox/sliver/releases/"
                    "download/v" version
                    "/sliver-client_linux-amd64"))
              (sha256
               (base32
                "1bnshf4n5hgpnzwnfni0p58n1m52kjwjsmb8nblpkmp466hjiqxh"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("sliver-client_linux-amd64" "bin/sliver-client"))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'install 'make-executable
                 (lambda _
                   (chmod (string-append #$output "/bin/sliver-client") #o755))))))
    (synopsis "Sliver C2 client")
    (description
     "Sliver is an open source cross-platform adversary emulation/red
team framework.  This package provides the client binary.")
    (home-page "https://github.com/BishopFox/sliver")
    (license license:gpl3)))

(define-public sliver-server
  (package
    (name "sliver-server")
    (version "1.7.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/BishopFox/sliver/releases/"
                    "download/v" version
                    "/sliver-server_linux-amd64"))
              (sha256
               (base32
                "1j6caziv5k2kzn7q3c6qzays7v3hbkcbd2sqniyfkrzn2b6nw8g3"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("sliver-server_linux-amd64" "bin/sliver-server"))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'install 'make-executable
                 (lambda _
                   (chmod (string-append #$output "/bin/sliver-server") #o755))))))
    (synopsis "Sliver C2 server")
    (description
     "Sliver is an open source cross-platform adversary emulation/red
team framework.  This package provides the server binary.")
    (home-page "https://github.com/BishopFox/sliver")
    (license license:gpl3)))
