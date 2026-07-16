(define-module (substrate kernel-space filesystem)
  #:use-module (gnu system file-systems)
  #:use-module (gnu system)
  #:export (kernel-file-systems kernel-swap-devices))

(define-public kernel-file-systems
  (cons* (file-system
           (mount-point "/boot/efi")
           (device (uuid "84F3-3015" 'fat32))
           (type "vfat"))
         (file-system
           (mount-point "/")
           (device (uuid "f0805da6-5c09-41e5-9a68-c4b2798909cc" 'ext4))
           (type "ext4")
           (needed-for-boot? #t))
         %base-file-systems))

(define-public kernel-swap-devices
  (list ((@ (gnu system) swap-space) (target (uuid "ba2b1983-3697-4124-8183-2d4528103325")))))
