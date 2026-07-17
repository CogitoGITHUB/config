(define-module (substrate user-space root shell csakura)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pkg-config)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (csakura))

(define-public csakura
  (package
    (name "csakura")
    (version "0.0.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/realstrawhat/csakura")
             (commit "9664fcbffac096acdb44cbc8c81527fb57d13639")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1dj1w456ljca4va1rc7qn3g4f69pg783aljwq0y9cx06iyip8cy4"))))
    (build-system gnu-build-system)
    (native-inputs (list pkg-config))
    (inputs (list ncurses))
    (arguments
     (list #:tests? #f
             #:make-flags #~(list "CC=gcc")
           #:phases
           #~(modify-phases %standard-phases
               (delete 'configure)
               (replace 'install
                 (lambda _
                   (invoke "make" "install"
                             (string-append "PREFIX=" #$output)))))))
    (home-page "https://github.com/realstrawhat/csakura")
    (synopsis "Sakura tree with falling petals for your terminal")
    (description
     "Csakura is a terminal animation that renders a procedurally grown
cherry-blossom tree with drifting petals.  Inspired by cmatrix and cava.")
    (license license:expat)))
