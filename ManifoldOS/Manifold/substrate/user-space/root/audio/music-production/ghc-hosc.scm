(define-module (substrate user-space root audio music-production ghc-hosc)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system haskell)
  #:use-module (gnu packages haskell-xyz)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (ghc-hosc))

(define-public ghc-hosc
  (package
    (name "ghc-hosc")
    (version "0.21.1")
    (source
     (origin
       (method url-fetch)
       (uri (hackage-uri "hosc" version))
       (sha256
        (base32 "1a01vp7d29503wa7sq0zy2az6zpyapjlmjszv50g2ykgb6as919v"))))
    (build-system haskell-build-system)
    (properties '((upstream-name . "hosc")))
    (inputs (list ghc-network ghc-blaze-builder ghc-safe))
    (home-page "http://rohandrape.net/t/hosc")
    (synopsis "Haskell Open Sound Control")
    (description "Haskell library implementing the Open Sound Control protocol")
    (license license:gpl3)))
