(define-module (substrate user-space home audio pipewire)
  #:use-module (gnu home services)
  #:use-module (gnu services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu home services desktop)
  #:use-module (gnu home services xdg)
  #:use-module (gnu packages linux)
  #:use-module (guix gexp)
  #:export (home-pipewire-service home-dbus-service))

(define-public home-dbus-service
  (service home-dbus-service-type))

(define pipewire-pkg (@ (gnu packages linux) pipewire))
(define wireplumber-pkg (@ (gnu packages linux) wireplumber))

(define wireplumber-config
  (plain-file "disable-logind.conf"
              "wireplumber.profiles = {
  main = {
    monitor.bluez.seat-monitoring = disabled
  }
}"))

(define (make-pw-env pkg)
  #~(append
      (default-environment-variables)
      (list "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
            "DBUS_SYSTEM_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket"
            "XDG_RUNTIME_DIR=/run/user/1000"
            (string-append "SPA_PLUGIN_PATH=" #$(file-append pipewire-pkg "/lib/spa-0.2"))
            (string-append "PIPEWIRE_MODULE_DIR=" #$(file-append pipewire-pkg "/lib/pipewire-0.3")))))

(define-public home-pipewire-service
  (simple-service 'pipewire-with-dbus
                  home-shepherd-service-type
                  (list
                    (shepherd-service
                      (provision '(pipewire))
                      (requirement '(dbus))
                      (start #~(make-forkexec-constructor
                                 (list #$(file-append pipewire-pkg "/bin/pipewire"))
                                 #:environment-variables #$(make-pw-env pipewire-pkg)))
                      (stop #~(make-kill-destructor))
                      (respawn? #t))
                    (shepherd-service
                      (provision '(wireplumber))
                      (requirement '(pipewire))
                      (start #~(make-forkexec-constructor
                                 (list #$(file-append wireplumber-pkg "/bin/wireplumber"))
                                 #:environment-variables #$(make-pw-env pipewire-pkg)))
                      (stop #~(make-kill-destructor))
                      (respawn? #t))
                    (shepherd-service
                      (provision '(pipewire-pulseaudio))
                      (requirement '(pipewire))
                      (start #~(make-forkexec-constructor
                                 (list #$(file-append pipewire-pkg "/bin/pipewire-pulse"))
                                 #:environment-variables #$(make-pw-env pipewire-pkg)))
                      (stop #~(make-kill-destructor))
                      (respawn? #t)))))