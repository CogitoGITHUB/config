(define-module (substrate user-space root loaders containers)
  #:use-module (substrate user-space root container-system podman)
  #:use-module (substrate user-space root container-system substrate-containerized)
  #:re-export (podman-packages podman-service manifoldos-image))
