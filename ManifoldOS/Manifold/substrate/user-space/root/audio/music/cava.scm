(define-module (substrate user-space root audio music cava)
  #:use-module (guix packages)
  #:use-module (gnu packages audio)
  #:export (cava))

(define-public cava
  (@@ (gnu packages audio) cava))
