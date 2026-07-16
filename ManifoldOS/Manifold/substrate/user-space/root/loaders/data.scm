(define-module (substrate user-space root loaders data)
  #:use-module (gnu packages databases)
  #:use-module (substrate user-space root data sqlit)
  #:re-export (postgresql)
  #:export (root-data-packages))

(define-public root-data-packages
  (list postgresql python-sqlit-tui))
