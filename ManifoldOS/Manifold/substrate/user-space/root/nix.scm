(define-module (substrate user-space root nix)
  #:use-module (gnu services)
  #:use-module (gnu services nix)
  #:use-module (gnu packages package-management)
  #:export (nix-packages nix-services))

(define-public nix-packages
  (list nix))

(define-public nix-services
  (list (service nix-service-type
                 (nix-configuration
                  (sandbox #t)
                  (extra-config
                   (list
                    "experimental-features = nix-command flakes\n"
                    "keep-outputs = true\n"
                    "keep-derivations = true\n"))))))
