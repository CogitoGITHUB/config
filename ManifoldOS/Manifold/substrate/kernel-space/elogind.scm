(define-module (substrate kernel-space elogind)
  #:use-module (gnu services)
  #:use-module (gnu services desktop)
  #:export (elogind-service))

;;; Elogind service configuration

(define-public elogind-service
  (service elogind-service-type
           (elogind-configuration
            (handle-lid-switch 'ignore)
            (handle-lid-switch-external-power 'ignore)
            (handle-lid-switch-docked 'ignore)
            (handle-power-key 'ignore)
            (handle-suspend-key 'ignore)
            (handle-hibernate-key 'ignore))))
