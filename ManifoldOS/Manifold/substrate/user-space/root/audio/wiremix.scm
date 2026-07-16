(define-module (substrate user-space root audio wiremix)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages base)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (wiremix))

(define-public wiremix
  (package
    (name "wiremix")
    (version "0.10.0")
    (source
      (origin
        (method url-fetch)
        (uri "file:///home/aoeu/.local/share/guix-binaries/wiremix")
        (sha256 (base32 "1qqv1gq2srql2ynyrff53cvpann4ps3g3fxyhwfy828hrdx2b77z"))))
    (build-system trivial-build-system)
    (inputs (list pipewire-minimal coreutils))
    (arguments
      (list #:modules '((guix build utils))
            #:builder
            #~(begin
                (use-modules (guix build utils))
                (let* ((out (assoc-ref %outputs "out"))
                       (src (assoc-ref %build-inputs "source")))
                  (mkdir-p (string-append out "/bin"))
                  (copy-file src (string-append out "/bin/wiremix"))
                  (chmod (string-append out "/bin/wiremix") #o755)))))
    (home-page "https://github.com/tsowell/wiremix")
    (synopsis "Simple TUI audio mixer for PipeWire")
    (description "Wiremix is a TUI audio mixer for PipeWire for adjusting volumes, routing audio, and configuring audio device settings.")
    (license license:expat)))
