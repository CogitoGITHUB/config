(define-module (substrate user-space root container-system podman)
  #:use-module (guix gexp)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (gnu services containers)
  #:use-module (gnu system accounts)
  #:use-module ((gnu packages containers) #:select (podman))
  #:export (podman-packages podman-service))

(define-public podman-packages
  (list podman))

(define-public podman-service
  (service rootless-podman-service-type
           (rootless-podman-configuration
            (podman podman)
            (subuids (list (subid-range (name "aoeu"))))
            (subgids (list (subid-range (name "aoeu")))))))
