(define-module (forms forms)
  #:use-module (forms osint osint)
  #:use-module (forms web-master web-master)
  #:use-module (forms monitoring monitoring)
  #:re-export (quien osint-packages
               caddy caddy-service-type web-master-packages web-master-services
               siomon monitoring-packages)
  #:export (forms-system-packages forms-system-services))

(define-public forms-system-packages
  (append osint-packages
          web-master-packages
          monitoring-packages))

(define-public forms-system-services
  (append web-master-services))
