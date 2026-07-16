(define-module (substrate user-space root loaders editors)
  #:use-module (substrate user-space root editors emacs)
  #:use-module (substrate user-space root editors neovim)
  #:re-export (emacs neovim)
  #:export (root-editors-packages))

(define-public root-editors-packages
  (list emacs neovim))
