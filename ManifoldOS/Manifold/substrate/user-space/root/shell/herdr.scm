(define-module (substrate user-space root shell herdr)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (herdr))

(define-public herdr
  (package
    (name "herdr")
    (version "0.7.5")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/ogulcancelik/herdr/releases/download/v" version
              "/herdr-linux-x86_64"))
        (sha256 (base32 "0lwjqnajw50rjaxxn5zxqr0r3jmwjyzffc4scwy2sk1y0y435j1x"))))
    (build-system trivial-build-system)
    (arguments
      '(#:modules ((guix build utils))
        #:builder
        (begin
          (use-modules (guix build utils))
          (let* ((out (assoc-ref %outputs "out"))
                 (bin (string-append out "/bin"))
                 (src (assoc-ref %build-inputs "source")))
            (mkdir-p bin)
            (copy-file src (string-append bin "/herdr"))
            (chmod (string-append bin "/herdr") #o555)))))
    (home-page "https://herdr.dev")
    (synopsis "Agent multiplexer that lives in your terminal")
    (description "Herdr is an agent-aware terminal multiplexer with workspaces, tabs, panes, mouse support, and session persistence. Detects agent states (blocked, working, done).")
    (license license:agpl3)))
