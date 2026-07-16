(define-module (forms web-master web-master)
  #:use-module (forms web-master back-end back-end)
  #:re-export (caddy caddy-service-type back-end-packages back-end-services)
  #:export (web-master-packages web-master-services))

(define-public web-master-packages
  (append back-end-packages))

(define-public web-master-services
  (append back-end-services))
