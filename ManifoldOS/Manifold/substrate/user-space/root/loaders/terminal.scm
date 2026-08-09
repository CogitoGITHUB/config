(define-module (substrate user-space root loaders terminal)
  #:use-module (substrate user-space root terminal ghostty)
  #:re-export (ghostty)
  #:export (root-terminal-packages))

(define-public root-terminal-packages
  (list ghostty))