(define-module (forms osint osint)
  #:use-module (forms osint quien)
  #:re-export (quien)
  #:export (osint-packages))

(define-public osint-packages
  (list quien))
