(define-module (substrate user-space root audio music-production ghc-tidal-core)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system haskell)
  #:use-module (gnu packages haskell-xyz)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (ghc-tidal-core))

(define-public ghc-tidal-core
  (package
    (name "ghc-tidal-core")
    (version "1.10.2")
    (source
     (origin
       (method url-fetch)
       (uri (hackage-uri "tidal-core" version))
       (sha256
        (base32 "078xddsr91q8z35bv37ks0ydkh81aay09i9za06czqh5dsvb1hl4"))))
    (build-system haskell-build-system)
    (properties '((upstream-name . "tidal-core")))
    (arguments
     (list
      #:tests? #f
      #:configure-flags '(list "--disable-tests")))
    (inputs (list ghc-colour))
    (home-page "https://tidalcycles.org")
    (synopsis "Core data types and functions for Tidal Cycles")
    (description "Core data types and functions for the Tidal Cycles live coding environment")
    (license license:gpl3)))

ghc-tidal-core
