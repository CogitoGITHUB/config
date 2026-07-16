(define-module (substrate user-space root shell broot)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:export (broot))

(define-public broot
  (package
    (name "broot")
    (version "1.57.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/Canop/broot/releases/"
                    "download/v" version
                    "/broot_" version ".zip"))
              (sha256
               (base32
                "1ibxj8gv6iq0lb86rh9x25gxdr9fvv9zyf0andhaypbab4h5v45r"))))
    (build-system trivial-build-system)
    (inputs
     (list unzip))
    (arguments
     (list #:modules (quote ((guix build utils)))
           #:builder
           (quasiquote (begin
             (use-modules (guix build utils))
             (let* ((out    (assoc-ref %outputs "out"))
                    (src    (assoc-ref %build-inputs "source"))
                    (unzip  (assoc-ref %build-inputs "unzip")))
               (setenv "PATH" (string-append unzip "/bin"))
               (mkdir-p (string-append out "/bin"))
               (invoke "unzip" src
                       "x86_64-unknown-linux-musl/broot"
                       "-d" out)
               (rename-file (string-append out "/x86_64-unknown-linux-musl/broot")
                            (string-append out "/bin/broot"))
               (delete-file-recursively (string-append out "/x86_64-unknown-linux-musl"))
               (chmod (string-append out "/bin/broot") #o555))))))
    (synopsis "Directory tree browser and file launcher")
    (description
     "broot is a directory tree browser and file launcher with fuzzy
search, git status integration, and custom commands.  It displays the
directory tree and lets you navigate, search, and open files.")
    (home-page "https://github.com/Canop/broot")
    (license license:expat)))
