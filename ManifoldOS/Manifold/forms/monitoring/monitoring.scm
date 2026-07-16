(define-module (forms monitoring monitoring)
  #:use-module (forms monitoring siomon)
  #:re-export (siomon)
  #:export (monitoring-packages))

(define-public monitoring-packages
  (list siomon))
