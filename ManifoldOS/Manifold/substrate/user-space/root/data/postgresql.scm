(define-module (substrate user-space root data postgresql)
  #:use-module (guix packages)
  #:use-module (gnu packages databases)
  #:export (postgresql))

(define-public postgresql
  (@@ (gnu packages databases) postgresql))
