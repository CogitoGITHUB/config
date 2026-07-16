(define-module (substrate user-space root sandbox sandbox)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages containers)
  #:export (sandbox-packages))

(define-public sandbox-packages
  (list firejail distrobox))
