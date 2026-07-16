(define-module (substrate user-space root shell rip)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gcc)
  #:export (rip-cli))

(define-public rip-cli
  (package
    (name "rip-cli")
    (version "0.7.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/cesarferreira/rip/releases/"
                    "download/v" version
                    "/rip-x86_64-unknown-linux-gnu.tar.gz"))
              (sha256
               (base32
                "152g8y4zicgrkz94cslzjy53ivdpzcq5w2kcbn27pmyasrzgznhn"))))
    (build-system copy-build-system)
    (native-inputs
     (list patchelf))
    (inputs
     (list glibc (list gcc "lib")))
    (arguments
     '(#:install-plan
       '(("rip" "bin/"))
       #:validate-runpath? #f
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'patch-interpreter
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out    (assoc-ref outputs "out"))
                    (bin    (string-append out "/bin/rip"))
                    (glibc  (assoc-ref inputs "glibc"))
                    (gcc    (assoc-ref inputs "gcc"))
                    (linker (string-append glibc
                                           "/lib/ld-linux-x86-64.so.2"))
                    (rpath  (string-append glibc "/lib:" gcc "/lib")))
               (invoke "patchelf"
                       "--set-interpreter" linker
                       "--set-rpath" rpath
                       bin)))))))
    (synopsis "Fuzzy find and kill processes from your terminal")
    (description
     "rip is a terminal-based process killer with fuzzy search, live
mode, port filtering, and multiple sort options.")
    (home-page "https://github.com/cesarferreira/rip")
    (license license:expat)))
