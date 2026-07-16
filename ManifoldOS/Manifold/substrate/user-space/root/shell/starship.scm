(define-module (substrate user-space root shell starship)
  #:use-module (guix packages)
  #:export (starship))

(define-public starship (@ (gnu packages shellutils) starship))