(define-module (substrate kernel-space bootloader)
  #:use-module (gnu bootloader)
  #:use-module ((gnu bootloader grub) #:prefix grub:)
  #:use-module (substrate kernel-space keyboard)
  #:export (system-bootloader-configuration))

;;; Bootloader configuration

(define-public system-bootloader-configuration
  (bootloader-configuration
    (bootloader grub:grub-efi-bootloader)
    (targets '("/boot/efi"))
    (keyboard-layout keyboard-layout)))
