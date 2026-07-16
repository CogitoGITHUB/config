(define-module (substrate user-space root shell power tlp)
  #:use-module (guix packages)
  #:export (tlp))

(define-public tlp (@ (gnu packages linux) tlp))