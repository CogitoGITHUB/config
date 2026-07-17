(define-module (substrate user-space root programming-languages lisp guile)
  #:use-module (gnu packages guile)
  #:use-module ((gnu packages guile-xyz) #:select (guile-ares-rs))
  #:re-export (guile-ares-rs)
  #:export (guile))

(define-public guile guile-3.0)