(define-module (substrate user-space root shell atuin)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base)
  #:use-module (substrate user-space root shell archive unzip)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (atuin))

(define-public atuin
  (package
    (name "atuin")
    (version "18.13.6")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/atuinsh/atuin/releases/download/v" version
              "/atuin-x86_64-unknown-linux-musl.tar.gz"))
        (sha256 (base32 "0gigapvzk2pbiw76dkrdslll96isjgq36camhs034vc1mnnjww8r"))))
    (build-system trivial-build-system)
    (inputs (list tar gzip))
    (arguments
      (list #:modules (quote ((guix build utils)))
            #:builder
        (quasiquote (begin
          (use-modules (guix build utils))
          (let* ((out (assoc-ref %outputs "out"))
                 (src (assoc-ref %build-inputs "source"))
                 (tar (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                 (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin")))
            (setenv "PATH" gzip)
            (mkdir-p (string-append out "/bin"))
            (invoke tar "-xzf" src
                    "--strip-components=1"
                    "-C" (string-append out "/bin")
                    "atuin-x86_64-unknown-linux-musl/atuin")
            (rename-file
              (string-append out "/bin/atuin")
              (string-append out "/bin/atuin")))))))
    (home-page "https://atuin.sh")
    (synopsis "Shell history manager")
    (description "Atuin replaces your shell history with a SQLite database.")
    (license license:asl2.0)))