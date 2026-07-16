(define-module (forms web-master back-end back-end)
  #:use-module (gnu services)
  #:use-module (forms web-master back-end caddy)
  #:re-export (caddy caddy-service-type)
  #:export (back-end-packages back-end-services))

(define-public back-end-packages
  (list caddy))

(define-public back-end-services
  (list (service caddy-service-type)))
