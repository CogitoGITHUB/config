(define-module (substrate user-space root loaders keyboard)
  #:use-module (substrate user-space root keyboard keyd)
  #:use-module (substrate user-space root keyboard kanata)
  #:use-module (substrate user-space root keyboard ditto)
  #:re-export (keyd kanata ditto)
  #:export (root-keyboard-packages root-keyboard-services))

(define-public root-keyboard-packages
  (list keyd kanata ditto))

(define-public root-keyboard-services
  (list kanata-service))