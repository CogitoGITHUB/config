(define-module (substrate user-space root shell power upower)
  #:use-module (guix packages)
  #:export (upower))

(define-public upower (@ (gnu packages gnome) upower))