(define-module (substrate user-space root loaders hardware)
  #:use-module (substrate user-space root hardware usbtree)
  #:export (root-hardware-packages))

(define-public root-hardware-packages
  (list usbtree))
