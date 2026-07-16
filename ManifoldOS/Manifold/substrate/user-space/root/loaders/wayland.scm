(define-module (substrate user-space root loaders wayland)
  #:use-module (substrate user-space root wayland appcards)
  #:re-export (appcards)
  #:export (root-desktop-wayland-packages))

(define-public root-desktop-wayland-packages
  (list appcards))
