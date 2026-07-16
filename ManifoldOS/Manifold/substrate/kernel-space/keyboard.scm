(define-module (substrate kernel-space keyboard)
  #:use-module (gnu system keyboard)
  #:use-module ((gnu system keyboard) #:renamer (lambda (sym)
                                                   (if (eq? sym 'keyboard-layout)
                                                       'gnu:keyboard-layout
                                                       sym)))
  #:export (keyboard-layout))

;;;; Keyboard configuration

(define-public keyboard-layout
  (gnu:keyboard-layout "us" "dvorak"
                    #:options '("caps:backspace")))
