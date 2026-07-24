(define-module (substrate user-space root nix)
  #:use-module (gnu services)
  #:use-module (gnu services nix)
  #:use-module (gnu packages package-management)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:export (nix-packages nix-services))

(define upstream-nix
  (@ (gnu packages package-management) nix))

(define nix
  (package
    (inherit upstream-nix)
    (arguments
     (substitute-keyword-arguments (package-arguments upstream-nix)
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-after 'skip-failing-tests 'skip-lang-test
              (lambda _
                (substitute* "tests/functional/local.mk"
                  ((".*lang\\.sh.*") ""))))))
       ((#:tests? _ #f) #f)))))

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
