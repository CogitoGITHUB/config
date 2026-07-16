(define-module (substrate user-space root loaders lsp)
  #:use-module (substrate user-space root lsp rust-analyzer)
  #:export (root-lsp-packages))

(define-public root-lsp-packages
  (list rust-analyzer))
