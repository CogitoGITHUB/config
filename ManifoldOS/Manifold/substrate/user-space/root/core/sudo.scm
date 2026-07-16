(define-module (substrate user-space root core sudo)
  #:use-module (guix packages)
  #:export (sudo))

(define-public sudo (@ (gnu packages admin) sudo))