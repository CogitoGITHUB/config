(define-module (substrate user-space root networking version-control lazygit)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (substrate user-space root shell archive unzip)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module (gnu packages base)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (lazygit))

(define-public lazygit
  (package
    (name "lazygit")
    (version "0.60.0")
    (source
      (origin
        (method url-fetch)
        (uri "https://github.com/jesseduffield/lazygit/releases/download/v0.60.0/lazygit_0.60.0_Linux_x86_64.tar.gz")
        (sha256 (base32 "05dbz7vr4igicf1dh2jx0rxsbkqhb4i58ywj1lzgvi4bz5ncllk2"))))
    (build-system trivial-build-system)
    (inputs (list gzip tar))
    (arguments
      (list #:modules (quote ((guix build utils)))
            #:builder
            (quasiquote (begin
              (use-modules (guix build utils))
              (let* ((out (assoc-ref %outputs "out"))
                     (src (assoc-ref %build-inputs "source"))
                     (tar (assoc-ref %build-inputs "tar"))
                     (gzip (assoc-ref %build-inputs "gzip")))
                (setenv "PATH" (string-append tar "/bin:" gzip "/bin"))
                (mkdir-p out)
                (invoke "tar" "-xzf" src "-C" out)
                (install-file (string-append out "/lazygit") (string-append out "/bin"))
                (delete-file (string-append out "/lazygit")))))))
    (home-page "https://github.com/jesseduffield/lazygit")
    (synopsis "Simple terminal UI for git commands")
    (description "A simple terminal UI for git commands, written in Go.")
    (license license:expat)))
