(define-module (substrate user-space root terminal wezterm)
  #:use-module (guix packages)
  #:export (wezterm))

(define-public wezterm (@ (gnu packages terminals) wezterm))