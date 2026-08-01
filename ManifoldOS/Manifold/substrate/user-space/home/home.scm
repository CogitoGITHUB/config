(define-module (substrate user-space home home)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services guix)
  #:use-module (gnu home services xdg)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu home services sound)
  #:use-module (gnu services)
  #:use-module (gnu services guix)
  #:use-module (guix gexp)
  #:use-module (substrate user-space home loaders audio)
  #:export (mappingos-home-environment))

(define-public mappingos-home-environment
  (home-environment
    (packages (list (@ (gnu packages pulseaudio) pulsemixer)))
    (services
     (append
      home-audio-services
      (list (simple-service 'pulseaudio-restart
                           home-shepherd-service-type
                           (list (shepherd-service
                                  (documentation "Restart PulseAudio at login")
                                  (start #~(lambda (_)
                                             (system* "pulseaudio" "-k")
                                             (sleep 1)
                                             (system* "pulseaudio" "--start")
                                             #t))
                                   (stop #~(const #f))
                                  (provision '(pulseaudio-restart))
                                  (respawn? #f))))
            (simple-service 'home-packages
                           home-profile-service-type
                           (list)))))))