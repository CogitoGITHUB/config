(define-module (substrate substrate)
  #:use-module (gnu system)
  #:use-module (gnu services)
  #:use-module (gnu services guix)
  #:use-module (gnu home)
  #:use-module (substrate kernel-space kernel-space)
  #:use-module (substrate user-space root root)
  #:use-module (substrate user-space home home)
  #:re-export (host-name system-timezone system-locale kernel kernel-arguments
               kernel-initrd kernel-firmware keyboard-layout
               system-bootloader-configuration kernel-file-systems
               kernel-swap-devices users groups
               sudoers-file setuid-programs root-system-packages
               kernel-system-services root-system-services
               mappingos-home-environment manifoldos-image))
