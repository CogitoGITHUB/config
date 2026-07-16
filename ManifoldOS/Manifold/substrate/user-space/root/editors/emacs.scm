(define-module (substrate user-space root editors emacs)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages sqlite)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:re-export (emacs)
  #:export (emacs-minimal-sqlite))

(define-public emacs-minimal-sqlite
  (package/inherit emacs
    (name "emacs-minimal-sqlite")
    (inputs (modify-inputs (package-inputs emacs)
              (prepend sqlite)))
    (arguments
     (substitute-keyword-arguments (package-arguments emacs)
       ((#:configure-flags flags)
        #~(append #$flags (list "--with-x-toolkit=no")))
       ((#:tests? _) #f)))))
