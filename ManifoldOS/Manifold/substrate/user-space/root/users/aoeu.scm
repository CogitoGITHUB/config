(define-module (substrate user-space root users aoeu)
  #:use-module (guix gexp)
  #:use-module (gnu system accounts)
  #:use-module (gnu system setuid)
  #:use-module (gnu packages admin)
  #:use-module (substrate user-space root shell nushell)
  #:export (users groups sudoers-file setuid-programs))

(define-public groups
  (list (user-group (name "root") (id 0) (system? #t))
        (user-group (name "wheel") (system? #t))
        (user-group (name "users") (system? #t))
        (user-group (name "nogroup") (system? #t))
        (user-group (name "tty") (id 996) (system? #t))
        (user-group (name "dialout") (system? #t))
        (user-group (name "kmem") (system? #t))
        (user-group (name "input") (system? #t))
        (user-group (name "video") (system? #t))
        (user-group (name "audio") (system? #t))
        (user-group (name "netdev") (system? #t))
        (user-group (name "lp") (system? #t))
        (user-group (name "disk") (system? #t))
        (user-group (name "floppy") (system? #t))
        (user-group (name "cdrom") (system? #t))
        (user-group (name "tape") (system? #t))
        (user-group (name "kvm") (system? #t))
        (user-group (name "sgx") (system? #t))
        (user-group (name "pulse") (system? #t))
        (user-group (name "pulse-access") (system? #t))
        (user-group (name "bluetooth") (system? #t))
        (user-group (name "podman") (system? #t))
        (user-group (name "greeter") (system? #t))))

(define-public users
  (list (user-account
         (name "aoeu")
         (comment "Aoeu")
         (group "users")
         (home-directory "/home/aoeu")
         (supplementary-groups '("wheel" "netdev" "audio" "video" "input" "uinput" "keyd" "podman" "pulse-access" "bluetooth"))
         (shell (file-append nushell "/bin/nu")))
        (user-account
         (name "pulse")
         (group "pulse")
         (system? #t)
         (supplementary-groups '("audio"))
         (home-directory "/var/run/pulse")
         (shell "/run/current-system/profile/bin/nologin"))
        (user-account
         (name "greeter")
         (group "greeter")
         (system? #t)
         (home-directory "/var/empty")
         (shell (file-append greetd "/sbin/agreety")))))

(define-public sudoers-file
  (plain-file "sudoers" "root ALL=(ALL) ALL
%wheel ALL=(ALL) NOPASSWD: ALL
"))

(define-public setuid-programs
  (list (setuid-program
         (program (file-append sudo "/bin/sudo")))))
