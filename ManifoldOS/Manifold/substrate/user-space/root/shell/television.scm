(define-module (substrate user-space root shell television)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base)
  #:use-module (substrate user-space root shell archive unzip)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (television))

(define-public television
  (package
    (name "television")
    (version "0.15.4")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/alexpasmantier/television/releases/download/" version
              "/tv-" version "-x86_64-unknown-linux-musl.tar.gz"))
        (sha256 (base32 "0in9wc8dnv62pbnmmx7rzham044wl10mws8mmgfvakajljxgdb4w"))))
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
                    (string-append "tv-" "0.15.4" "-x86_64-unknown-linux-musl/tv")))))))
    (home-page "https://github.com/alexpasmantier/television")
    (synopsis "Fast fuzzy finder TUI")
    (description "Television is a fast fuzzy finder for the terminal.")
    (license license:expat)))