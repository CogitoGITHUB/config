(define-module (substrate user-space root audio wireplumber)
  #:use-module (guix packages)
  #:use-module (gnu packages linux)
  #:export (wireplumber))

(define-public wireplumber (@ (gnu packages linux) wireplumber))
