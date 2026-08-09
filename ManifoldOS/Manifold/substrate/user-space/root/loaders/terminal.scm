(define-module (substrate user-space root loaders terminal)
  #:use-module (substrate user-space root terminal wezterm)
  #:use-module (substrate user-space root terminal ghostty)
  #:re-export (wezterm ghostty)
  #:export (root-terminal-packages))

(define-public root-terminal-packages
  (list wezterm ghostty))