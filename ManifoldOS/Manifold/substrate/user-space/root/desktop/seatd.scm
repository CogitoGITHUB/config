(define-module (substrate user-space root desktop seatd)
  #:use-module (gnu packages admin)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:export (seatd seatd-service))

(define-public seatd (@ (gnu packages admin) seatd))

(define-public seatd-service
  (simple-service 'seatd
                  shepherd-root-service-type
                  (list (shepherd-service
                          (provision '(seatd))
                          (requirement '(user-processes))
                          (documentation "Minimal seat management daemon")
                          (start #~(make-forkexec-constructor
                                    (list #$(file-append seatd "/bin/seatd")
                                          "-g" "seat")
                                    #:log-file "/var/log/seatd.log"))
                          (stop #~(make-kill-destructor))
                          (respawn? #t)))))