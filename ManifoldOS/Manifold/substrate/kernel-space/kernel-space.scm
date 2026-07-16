(define-module (substrate kernel-space kernel-space)
#:use-module (substrate kernel-space linux)
#:use-module (substrate kernel-space keyboard)
#:use-module (substrate kernel-space bootloader)
#:use-module (substrate kernel-space filesystem)
#:use-module (substrate kernel-space hostname)
#:use-module (substrate kernel-space locale)
#:use-module (substrate kernel-space elogind)
#:use-module (substrate kernel-space udev)
#:use-module (substrate kernel-space kmod)
#:re-export (kernel kernel-arguments kernel-modules kernel-initrd kernel-firmware
  keyboard-layout system-bootloader-configuration kernel-file-systems kernel-swap-devices host-name
  system-locale system-timezone elogind-service udev-rules udev-service-type
  udev-configuration uinput-group-service)
#:export (kernel-system-services kernel-system-packages))

(define kernel-system-services
  (list elogind-service uinput-group-service kernel-modules))

(define kernel-system-packages kernel-firmware)