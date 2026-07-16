(define-module (substrate user-space root desktop quickshell)
  #:use-module (guix packages)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages qt)
  #:export (quickshell))

(define-public quickshell
  (let ((orig (@@ (gnu packages wm) quickshell)))
    (package
      (inherit orig)
      (inputs `(("qtwayland" ,qtwayland)
                ,@(package-inputs orig))))))

quickshell
