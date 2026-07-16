(define-module (substrate user-space root networking tailscale)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base)
  #:use-module (substrate user-space root shell archive unzip)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (tailscale config-tailscaled-service-type))

(define-public tailscale
  (package
    (name "tailscale")
    (version "1.96.2")
    (source
      (origin
        (method url-fetch)
        (uri "https://pkgs.tailscale.com/stable/tailscale_1.96.2_amd64.tgz")
        (sha256 (base32 "00blgy5j5x0zp45xvy421mpkg5bdvzf2gnbywil3rnspxhysz8na"))))
    (build-system trivial-build-system)
    (inputs (list tar gzip))
    (arguments
      (list #:modules (quote ((guix build utils)))
            #:builder
        (quasiquote (begin
          (use-modules (guix build utils))
          (let* ((out (assoc-ref %outputs "out"))
                 (src (assoc-ref %build-inputs "source"))
                 (tar (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                 (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin")))
            (setenv "PATH" gzip)
            (mkdir-p (string-append out "/bin"))
            (invoke tar "-xzf" src
                    "--strip-components=1"
                    "-C" (string-append out "/bin")
                    "tailscale_1.96.2_amd64/tailscale"
                    "tailscale_1.96.2_amd64/tailscaled"))))))
    (home-page "https://tailscale.com/")
    (synopsis "Tailscale VPN")
    (description "Tailscale is a zero-config VPN.")
    (license license:bsd-3)))

(define (tailscale-shepherd-service config)
  (let ((tailscaled-bin (file-append tailscale "/bin/tailscaled")))
    (list (shepherd-service
           (documentation "Run the tailscale daemon")
           (provision (quote (tailscaled tailscale)))
           (requirement (quote (user-processes)))
            (start #~(begin
                       (use-modules (srfi srfi-1) (srfi srfi-26))
                       (lambda _
                         (fork+exec-command (list #$tailscaled-bin)))))
             (stop #~(begin
                       (use-modules (srfi srfi-1) (srfi srfi-26))
                       (make-kill-destructor)))))))

(define-public config-tailscaled-service-type
  (service-type
    (name (quote config-tailscaled))
    (extensions
      (list (service-extension shepherd-root-service-type tailscale-shepherd-service)))
    (default-value (quote ()))
    (description "Run tailscaled daemon")))