(define-module (substrate user-space root loaders emacs-packages)
  #:use-module (substrate user-space root emacs-packages emacs-packages)
  #:re-export (emacs-packages)
  #:export (root-emacs-packages))

(define-public root-emacs-packages emacs-packages)