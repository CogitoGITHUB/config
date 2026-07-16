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
  #:use-module (substrate user-space root editors emacs)
  #:use-module (substrate user-space home loaders audio)
  #:export (mappingos-home-environment))

(define (emacs-shepherd-service config)
  (list (shepherd-service
          (provision '(emacs-daemon))
          (documentation "Emacs daemon (emacs-minimal-sqlite)")
          (start #~(make-forkexec-constructor
                    (list #$(file-append emacs-minimal-sqlite "/bin/emacs") "--fg-daemon")
                    #:environment-variables
                    (list (string-append "PATH=" #$(file-append emacs-minimal-sqlite "/bin")
                                         ":" (or (getenv "PATH") ""))
                          (string-append "XDG_RUNTIME_DIR=" (or (getenv "XDG_RUNTIME_DIR")
                                                                (string-append "/run/user/" (number->string (getuid))))))))
          (stop #~(make-kill-destructor)))))

(define emacs-daemon-service-type
  (service-type
    (name 'emacs-daemon)
    (extensions
      (list (service-extension
              home-shepherd-service-type
              emacs-shepherd-service)))
    (default-value #f)
    (description "Run Emacs as a daemon using Shepherd")))

(define-public emacs-daemon-service
  (service emacs-daemon-service-type))

(define-public mappingos-home-environment
  (home-environment
    (packages (list (@ (gnu packages pulseaudio) pulsemixer)))
    (services
     (append
      home-audio-services
      (list emacs-daemon-service
            (simple-service 'pulseaudio-restart
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