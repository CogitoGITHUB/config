(define-module (substrate user-space root networking lazyssh)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages elf)
  #:export (lazyssh))

(define-public lazyssh
  (package
    (name "lazyssh")
    (version "0.3.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/Adembc/lazyssh/releases/"
                    "download/v" version
                    "/lazyssh_Linux_x86_64.tar.gz"))
              (sha256
               (base32
                "1ncajb1h7z62f0xl2iq2xghf0v851rd0s132h3whb2blmxpik1ry"))))
    (build-system copy-build-system)
    (native-inputs (list patchelf))
    (inputs (list glibc))
    (arguments
     (list #:install-plan
           #~'(("lazyssh" "bin/lazyssh"))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'install 'patch-elf
                 (lambda _
                   (let* ((out   #$output)
                          (bin   (string-append out "/bin/lazyssh"))
                          (glibc (assoc-ref %build-inputs "glibc"))
                          (linker (string-append glibc "/lib/ld-linux-x86-64.so.2")))
                     (invoke "patchelf" "--set-interpreter" linker bin)))))))
    (synopsis "Terminal-based SSH manager")
    (description
     "Lazyssh is a terminal-based interactive SSH manager inspired by
lazydocker and k9s.  It reads servers from ~/.ssh/config, supports fuzzy
search, pinning, tagging, port forwarding, key management, and more.")
    (home-page "https://github.com/Adembc/lazyssh")
    (license license:asl2.0)))
