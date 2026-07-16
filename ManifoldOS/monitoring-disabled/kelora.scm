(define-module (substrate user-space root monitoring kelora)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (kelora))

(define-public kelora
  (package
    (name "kelora")
    (version "0.1.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/dloss/kelora/releases/latest/download/kelora-x86_64-unknown-linux-musl.tar.gz"))
              (sha256
               (base32
                "1sn3rp2r8a6lf3zh95wjsf4cfn77gpyahrs4q7f8jm08jzs4bbra"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("kelora" "bin/"))))
    (synopsis "Scriptable log processor for the command line")
    (description "Kelora is a scriptable log processor for the command line. Parse structured or semi-structured logs, filter with complex logic, and analyze streams using embedded Rhai scripting—all in a single binary.")
    (home-page "https://github.com/dloss/kelora")
    (license license:expat)))
