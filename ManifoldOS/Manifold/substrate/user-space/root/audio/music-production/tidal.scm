(define-module (substrate user-space root audio music-production tidal)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system haskell)
  #:use-module (gnu packages haskell-xyz)
  #:use-module (gnu packages audio)
  #:use-module (substrate user-space root audio music-production ghc-hosc)
  #:use-module (substrate user-space root audio music-production ghc-tidal-core)
  #:use-module (substrate user-space root audio music-production ghc-tidal-link)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (tidal))

(define-public tidal
  (package
    (name "tidal")
    (version "1.10.3")
    (source
     (origin
       (method url-fetch)
       (uri (hackage-uri "tidal" version))
       (sha256
        (base32 "0ijh78brksq2qqnhjimvi8458iqyp52vnw0ivhpb4xbn6ac738ax"))))
    (build-system haskell-build-system)
    (properties '((upstream-name . "tidal")))
    (arguments
     (list
      #:tests? #f
      #:configure-flags '(list "--disable-tests")))
    (inputs (list ghc-clock ghc-colour ghc-exceptions ghc-hosc
                  ghc-network ghc-primitive ghc-random
                  ghc-tidal-core ghc-tidal-link))
    (home-page "https://tidalcycles.org")
    (synopsis "Pattern language for live coding algorithmic music")
    (description
     "Tidal is a domain specific language for live coding patterns.  It
allows you to make music with patterns by writing Haskell code, and is
typically used with the SuperCollider synthesiser as a sound engine.")
    (license license:gpl3)))

tidal
