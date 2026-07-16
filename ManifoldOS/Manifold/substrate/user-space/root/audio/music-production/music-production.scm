(define-module (substrate user-space root audio music-production music-production)
  #:use-module (substrate user-space root audio music-production ghc-hosc)
  #:use-module (substrate user-space root audio music-production ghc-tidal-core)
  #:use-module (substrate user-space root audio music-production ghc-tidal-link)
  #:use-module (substrate user-space root audio music-production tidal)
  #:export (music-production-packages))

(define-public music-production-packages
  (list ghc-hosc ghc-tidal-core ghc-tidal-link tidal))

music-production-packages
