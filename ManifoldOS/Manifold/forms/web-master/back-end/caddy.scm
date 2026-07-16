(define-module (forms web-master back-end caddy)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (guix build-system copy)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (caddy caddy-service-type))

(define-public caddy
  (package
    (name "caddy")
    (version "2.11.4")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/caddyserver/caddy/releases/download/v" version
              "/caddy_" version "_linux_amd64.tar.gz"))
        (sha256 (base32 "1fbvxj6mifdqhwm5s1f8snr805k0anllzlri7cg9l61rgj8vyzsj"))))
    (build-system copy-build-system)
    (arguments '(#:install-plan '(("caddy" "bin/"))))
    (native-inputs (list gzip))
    (home-page "https://caddyserver.com")
    (synopsis "Web server with automatic HTTPS")
    (description
     "Caddy is a web server with automatic HTTPS via Let's Encrypt.
It features a concise Caddyfile configuration, HTTP/2, HTTP/3, and
built-in reverse proxying.")
    (license license:asl2.0)))

;; ── Shepherd Service ──

(define-record-type* <caddy-configuration>
  caddy-configuration make-caddy-configuration
  caddy-configuration?
  (caddy       caddy-configuration-caddy
               (default caddy))
  (config-file caddy-configuration-config-file
               (default "/etc/caddy/Caddyfile")))

(define (caddy-shepherd-service config)
  (let ((pkg        (caddy-configuration-caddy config))
        (config-file (caddy-configuration-config-file config)))
    (list (shepherd-service
           (provision '(caddy))
           (requirement '(networking))
           (documentation "Run the Caddy web server")
           (start #~(make-forkexec-constructor
                     (list #$(file-append pkg "/bin/caddy")
                           "run" "--config" #$config-file)
                     #:log-file "/var/log/caddy.log"))
           (stop #~(make-kill-destructor))
           (auto-start? #f)))))

(define-public caddy-service-type
  (service-type
    (name 'caddy)
    (extensions
      (list (service-extension shepherd-root-service-type
                               (lambda (config)
                                 (caddy-shepherd-service config)))))
    (default-value (caddy-configuration))
    (description "Run the Caddy web server as a Shepherd service.")))
