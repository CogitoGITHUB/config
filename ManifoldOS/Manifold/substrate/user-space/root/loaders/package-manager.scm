(define-module (substrate user-space root loaders package-manager)
  #:use-module (substrate user-space root package-manager nix)
  #:re-export (nix)
  #:export (root-package-manager-packages))

(define-public root-package-manager-packages
  (list nix))