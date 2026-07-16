(define-module (substrate user-space root shell carapace)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base)
  #:use-module (substrate user-space root shell archive unzip)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (carapace))

(define-public carapace
  (package
    (name "carapace")
    (version "1.6.4")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/carapace-sh/carapace-bin/releases/download/v" version
              "/carapace-bin_" version "_linux_amd64.tar.gz"))
        (sha256 (base32 "1wpg8l0s6xcd7hjk3ifaqlkb9azdqik3j4nqa07ccndp1bwyjpl8"))))
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
            (setenv "PATH" (string-append gzip ":" (getenv "PATH")))
            (mkdir-p (string-append out "/bin"))
            (invoke tar "-xzf" src
                    "-C" (string-append out "/bin")
                    "carapace"))))))
    (home-page "https://carapace.sh")
    (synopsis "Shell completion framework")
    (description "Carapace is a shell completion framework.")
    (license license:asl2.0)))
