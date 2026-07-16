(define-module (substrate user-space root keyboard ditto)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (gnu packages base)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (ditto))

(define-public ditto
  (package
    (name "ditto")
    (version "1.0.5")
    (source
      (origin
        (method url-fetch)
        (uri "https://github.com/arvingarciabtw/ditto/releases/download/v1.0.5/ditto_linux_amd64")
        (sha256 (base32 "0h31sylla4xc95f8lrjg0z7d81acz2rhijnbbjjh2a94s0nmscb7"))))
    (build-system trivial-build-system)
    (inputs (list patchelf glibc `(,gcc "lib")))
    (arguments
      (list #:modules (quote ((guix build utils)))
            #:builder
        (quasiquote (begin
          (use-modules (guix build utils))
          (let* ((out (assoc-ref %outputs "out"))
                 (src (assoc-ref %build-inputs "source"))
                 (patchelf (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
                 (glibc (assoc-ref %build-inputs "glibc"))
                 (gcc-lib (assoc-ref %build-inputs "gcc"))
                 (interp (string-append glibc "/lib/ld-linux-x86-64.so.2"))
                 (rpath (string-append gcc-lib "/lib")))
            (mkdir-p (string-append out "/bin"))
            (copy-file src (string-append out "/bin/ditto"))
            (chmod (string-append out "/bin/ditto") #o755)
            (invoke patchelf "--set-interpreter" interp
                    "--set-rpath" rpath
                    (string-append out "/bin/ditto"))
)))))
    (home-page "https://github.com/arvingarciabtw/ditto")
    (synopsis "Keyboard visualizer for Todoist and other apps")
    (description
     "Ditto is a keyboard visualizer that displays keypresses on screen,
useful for presentations, streaming, and screencasts.")
    (license license:asl2.0)))
