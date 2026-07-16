(define-module (substrate user-space root shell archive unzip)
  #:use-module (guix packages)
  #:export (unzip))

(define-public unzip (@ (gnu packages compression) unzip))