(define-module (substrate user-space root networking noodle)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (gnu packages base)
  #:use-module (gnu packages elf)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (noodle))

(define-public noodle
  (package
    (name "noodle")
    (version "0.3.2")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "https://github.com/wilfredinni/noodle/releases/download/v"
                            version "/noodle-linux-x86_64"))
        (sha256 (base32 "0jpzwhfzr6gjgc85r5kknh7apmhd432vpb6awb6fh7i42pd7fmjj"))))
    (build-system trivial-build-system)
    (inputs (list patchelf glibc))
    (arguments
      (list #:modules (quote ((guix build utils)))
            #:builder
        (quasiquote (begin
          (use-modules (guix build utils))
          (let* ((out (assoc-ref %outputs "out"))
                 (src (assoc-ref %build-inputs "source"))
                 (patchelf (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
                 (glibc (assoc-ref %build-inputs "glibc"))
                 (interp (string-append glibc "/lib/ld-linux-x86-64.so.2")))
            (mkdir-p (string-append out "/bin"))
            (copy-file src (string-append out "/bin/noodle"))
            (chmod (string-append out "/bin/noodle") #o755)
            (invoke patchelf "--set-interpreter" interp
                    (string-append out "/bin/noodle")))))))
    (home-page "https://github.com/wilfredinni/noodle")
    (synopsis "REST client in the terminal")
    (description
     "Noodle is a REST client in the terminal.  It provides a terminal
user interface for making HTTP requests and viewing responses.")
    (license license:expat)))
