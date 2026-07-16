(define-module (substrate user-space root shell psleep)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gcc)
  #:export (psleep))

(define-public psleep
  (package
    (name "psleep")
    (version "0.3.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/Yesh-02/psleep/releases/"
                    "download/v" version
                    "/psleep-v" version "-x86_64-unknown-linux-gnu.tar.gz"))
              (sha256
               (base32
                "0znpk7zb42ip2vzm099ypfizq9sslkynff083a8q7qx6jdk1jdiw"))))
    (build-system copy-build-system)
    (native-inputs
     (list patchelf))
    (inputs
     (list glibc (list gcc "lib")))
    (arguments
     '(#:install-plan
       '(("psleep" "bin/"))
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'patch-interpreter
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out    (assoc-ref outputs "out"))
                    (bin    (string-append out "/bin/psleep"))
                    (glibc  (assoc-ref inputs "glibc"))
                    (gcc    (assoc-ref inputs "gcc"))
                    (linker (string-append glibc
                                           "/lib/ld-linux-x86-64.so.2"))
                    (rpath  (string-append glibc "/lib:" gcc "/lib")))
               (invoke "patchelf"
                       "--set-interpreter" linker
                       "--set-rpath" rpath
                       bin)))))))
    (synopsis "Sleep with a live progress bar")
    (description
     "psleep is a tiny, fast CLI utility that works just like sleep
but shows a live progress bar.  Supports human-friendly durations,
multiple animation styles, and configurable via flags or env vars.")
    (home-page "https://github.com/Yesh-02/psleep")
    (license license:asl2.0)))
