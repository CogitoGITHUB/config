(define-module (substrate user-space root networking bluetuith)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (bluetuith))

(define-public bluetuith
  (package
    (name "bluetuith")
    (version "0.2.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/bluetuith-org/bluetuith/releases/download/v" version "/bluetuith_" version "_Linux_x86_64.tar.gz"))
        (sha256
         (base32 "05r7lvpqlxib591zf74i29xg0gpdc7wqip07k7issin42qfp61pj"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("bluetuith" "bin/bluetuith"))))
    (home-page "https://github.com/bluetuith-org/bluetuith")
    (synopsis "Cross-platform TUI bluetooth manager")
    (description "bluetuith is a TUI-based bluetooth connection manager that can interact
with bluetooth adapters and devices. It aims to be a replacement for most
bluetooth managers like blueman.")
    (license license:gpl3)))
