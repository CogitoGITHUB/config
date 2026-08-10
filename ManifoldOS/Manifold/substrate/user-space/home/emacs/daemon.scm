(define-module (substrate user-space home emacs daemon)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (guix gexp)
  #:use-module (substrate user-space root editors emacs)
  #:export (home-emacs-daemon-service))

(define-public home-emacs-daemon-service
  (simple-service 'emacs-daemon
                  home-shepherd-service-type
                  (list
                    (shepherd-service
                      (provision '(emacs))
                      (documentation "Start the Emacs daemon for use with emacsclient.")
                      (requirement '())
                      (start #~(make-forkexec-constructor
                                 (list #$(file-append emacs-minimal-sqlite "/bin/emacs")
                                       "--daemon")
                                 #:environment-variables
                                 (list (string-append "HOME=" (getenv "HOME"))
                                       (string-append "XDG_RUNTIME_DIR=/run/user/"
                                                      (number->string (getuid)))
                                       "EMACS_NATIVECOMP_AOTCOMP=no"
                                       "EMACS_NATIVECOMP_DRIVER=no")
                                 #:log-file "/tmp/opencode/emacs-daemon.log"
                                 #:directory (getenv "HOME")))
                      (stop #~(make-kill-destructor))
                      (respawn? #f)
                      (one-shot? #f)))))