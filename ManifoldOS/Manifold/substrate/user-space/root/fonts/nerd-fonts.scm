(define-module (substrate user-space root fonts nerd-fonts)
  #:use-module (gnu packages fonts)
  #:export (font-packages))

(define-public font-packages
  (list font-terminus font-termsyn))
