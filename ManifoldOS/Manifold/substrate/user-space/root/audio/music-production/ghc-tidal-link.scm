(define-module (substrate user-space root audio music-production ghc-tidal-link)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system haskell)
  #:use-module (gnu packages gcc)
  #:use-module (substrate user-space root audio music-production ghc-hosc)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (ghc-tidal-link))

(define-public ghc-tidal-link
  (package
    (name "ghc-tidal-link")
    (version "1.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (hackage-uri "tidal-link" version))
       (sha256
        (base32 "179f41ckvqvyawj6z7asp987838ivpj1dgi5f3n97biz15qxlklc"))))
    (build-system haskell-build-system)
    (properties '((upstream-name . "tidal-link")))
    (arguments
     (list
      #:tests? #f
      #:configure-flags '(list "--disable-tests")))
    (inputs (list gcc ghc-hosc))
    (home-page "https://tidalcycles.org")
    (synopsis "Ableton Link integration for Tidal Cycles")
    (description "Haskell interface to Ableton Link for tempo synchronisation in Tidal Cycles")
    (license license:gpl3)))

ghc-tidal-link
