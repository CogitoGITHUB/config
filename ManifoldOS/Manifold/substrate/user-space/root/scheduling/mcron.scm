(define-module (substrate user-space root scheduling mcron)
  #:use-module (guix packages)
  #:use-module (gnu packages admin)
  #:export (mcron))

(define-public mcron
  (@@ (gnu packages admin) mcron))
