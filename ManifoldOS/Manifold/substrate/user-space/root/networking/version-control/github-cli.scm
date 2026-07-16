(define-module (substrate user-space root networking version-control github-cli)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base)
  #:use-module (substrate user-space root shell archive unzip)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (github-cli))

(define-public github-cli
  (package
    (name "github-cli")
    (version "2.63.2")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/cli/cli/releases/download/v" version
              "/gh_" version "_linux_amd64.tar.gz"))
        (sha256 (base32 "007d5lkh02wsq6g0z7d24f4hg2d2hyvx5ibgfkxhbc4wl8fdnbwi"))))
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
                    "--strip-components=2"
                    "-C" (string-append out "/bin")
                    "gh_2.63.2_linux_amd64/bin/gh"))))))
    (home-page "https://cli.github.com/")
    (synopsis "GitHub CLI tool")
    (description "gh is the official GitHub command line tool.")
    (license license:asl2.0)))