(define-module (substrate substrate-containerized)
  #:use-module (gnu system)
  #:use-module (gnu services)
  #:use-module (gnu bootloader)
  #:use-module (gnu bootloader grub)
  #:use-module (gnu system file-systems)
  #:use-module (gnu services containers)
  #:use-module (substrate substrate)
  #:export (manifoldos-image))

(define container-os
  (operating-system
    (host-name "manifoldos")
    (timezone "UTC")
    (locale "en_US.utf8")
    (bootloader (bootloader-configuration
                  (bootloader grub-bootloader)
                  (targets '("/dev/sda"))))
    (file-systems %base-file-systems)))

(define-public manifoldos-image
  (oci-image
    (repository "manifoldos")
    (tag "latest")
    (value container-os)))
