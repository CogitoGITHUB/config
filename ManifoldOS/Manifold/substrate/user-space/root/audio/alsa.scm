(define-module (substrate user-space root audio alsa)
  #:use-module (gnu services)
  #:use-module (gnu packages linux)
  #:use-module (gnu services sound)
  #:use-module (guix gexp)
  #:export (alsa-utils alsa-service))

(define-public alsa-utils
  (@@ (gnu packages linux) alsa-utils))

(define-public alsa-service
  (simple-service 'alsa-unmute
                  boot-service-type
                   #~(begin
                       (use-modules (srfi srfi-1) (srfi srfi-26))
                       (system* #$(file-append (@@ (gnu packages linux) alsa-utils) "/bin/amixer")
                                "sset" "Master" "unmute")
                       (system* #$(file-append (@@ (gnu packages linux) alsa-utils) "/bin/amixer")
                                "sset" "Master" "100%"))))
