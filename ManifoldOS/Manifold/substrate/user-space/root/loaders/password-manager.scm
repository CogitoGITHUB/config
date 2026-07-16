(define-module (substrate user-space root loaders password-manager)
  #:use-module (substrate user-space root password-manager password-store)
  #:use-module (substrate user-space root password-manager pass-extensions)
  #:use-module (substrate user-space root password-manager passff-host)
  #:re-export (password-store pass-otp pass-update passff-host)
  #:export (root-password-manager-packages))

(define-public root-password-manager-packages
  (list password-store pass-otp pass-update passff-host))
