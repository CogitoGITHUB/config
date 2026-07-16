(define-module (substrate user-space root shell nur)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages compression)
  #:export (nur))

(define-public nur
  (package
    (name "nur")
    (version "0.28.1+0.113.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/nur-taskrunner/nur/releases/"
                    "download/v" version
                    "/nur-" version "-x86_64-unknown-linux-gnu.tar.gz"))
              (sha256
               (base32
                "1jfq3c71sw5mriyy84p6jaysjd5kfxqsz3z88fzixraja8bmvcaw"))))
    (build-system copy-build-system)
    (native-inputs
     (list patchelf gzip tar))
    (inputs
     (list glibc (list gcc "lib")))
    (arguments
     '(#:install-plan
       '(("nur-0.28.1+0.113.1-x86_64-unknown-linux-gnu/nur" "bin/nur"))
       #:phases
       (modify-phases %standard-phases
         (replace 'unpack
           (lambda* (#:key source #:allow-other-keys)
             (invoke "tar" "-xzf" source)
             #t))
         (add-after 'install 'patch-interpreter
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out    (assoc-ref outputs "out"))
                    (bin    (string-append out "/bin/nur"))
                    (glibc  (assoc-ref inputs "glibc"))
                    (gcc    (assoc-ref inputs "gcc"))
                    (linker (string-append glibc
                                           "/lib/ld-linux-x86-64.so.2"))
                    (rpath  (string-append glibc "/lib:" gcc "/lib")))
               (chmod bin #o755)
               (invoke "patchelf"
                       "--set-interpreter" linker
                       "--set-rpath" rpath
                       bin)))))))
    (synopsis "Task runner based on nushell")
    (description
     "nur is a task runner that uses nushell scripting to define tasks.
It borrows ideas from b5 and just, and allows well-structured tasks
using the super-powers of nushell.")
    (home-page "https://github.com/nur-taskrunner/nur")
    (license license:expat)))
