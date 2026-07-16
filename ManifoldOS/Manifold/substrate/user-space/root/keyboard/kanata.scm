(define-module (substrate user-space root keyboard kanata)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gcc)
  #:use-module (substrate user-space root shell archive unzip)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (kanata kanata-service))

(define-public kanata
  (package
    (name "kanata")
    (version "1.11.0")
    (source
      (origin
        (method url-fetch)
        (uri "https://github.com/jtroo/kanata/releases/download/v1.11.0/linux-binaries-x64.zip")
        (sha256 (base32 "1qmlb5a54hgri65c8v19hd6jshsvss7rkwxc5b67iw67njpk9xnr"))))
    (build-system trivial-build-system)
    (inputs (list unzip patchelf glibc `(,gcc "lib")))
    (arguments
      (list #:modules (quote ((guix build utils)))
            #:builder
        (quasiquote (begin
          (use-modules (guix build utils))
          (let* ((out (assoc-ref %outputs "out"))
                 (src (assoc-ref %build-inputs "source"))
                 (unzip (string-append (assoc-ref %build-inputs "unzip") "/bin/unzip"))
                 (patchelf (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
                 (glibc (assoc-ref %build-inputs "glibc"))
                 (gcc-lib (assoc-ref %build-inputs "gcc"))
                 (interp (string-append glibc "/lib/ld-linux-x86-64.so.2"))
                 (rpath (string-append gcc-lib "/lib")))
            (mkdir-p (string-append out "/bin"))
            (invoke unzip "-j" src "kanata_linux_x64" "-d" (string-append out "/bin"))
            (rename-file (string-append out "/bin/kanata_linux_x64")
                         (string-append out "/bin/kanata"))
            (invoke patchelf "--set-interpreter" interp
                    "--set-rpath" rpath
                    (string-append out "/bin/kanata")))))))
    (home-page "https://github.com/jtroo/kanata")
    (synopsis "Keyboard remapper")
    (description "Kanata is a keyboard remapper for Linux.")
    (license license:lgpl3)))

(define-public kanata-service
  (simple-service 'kanata
                  shepherd-root-service-type
                  (list (shepherd-service
                          (provision '(kanata))
                          (requirement '(user-processes))
                          (start #~(make-forkexec-constructor
                                     (list #$(file-append kanata "/bin/kanata")
                                           "--cfg" "/home/aoeu/.config/kanata/kanata.kbd")
                                     #:log-file "/var/log/kanata.log"))
                          (stop #~(make-kill-destructor))
                          (respawn? #t)))))
