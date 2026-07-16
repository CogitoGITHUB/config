(define-module (substrate user-space root loaders formatters)
  #:use-module (substrate user-space root formatters nixfmt)
  #:use-module (substrate user-space root formatters ruff)
  #:use-module (substrate user-space root formatters latexindent)
  #:use-module (substrate user-space root formatters prettier)
  #:export (root-formatters-packages))

(define-public root-formatters-packages
  (list nixfmt
        ruff
        texlive-latexindent
        node))
