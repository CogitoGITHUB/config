(define-module (substrate user-space root ai headless-terminal)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module (gnu packages elf)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (headless-terminal))

(define-public headless-terminal
  (package
    (name "headless-terminal")
    (version "0.3.0")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/montanaflynn/headless-terminal/releases/download/v" version
              "/ht-v" version "-linux-amd64.tar.gz"))
        (sha256 (base32 "0xhiqcn20b7y2shfm1hk8s83li2wajf4ls46as2lrmiia4jg7pa7"))))
    (build-system trivial-build-system)
    (inputs (list tar gzip patchelf glibc))
    (arguments
     '(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let* ((out (assoc-ref %outputs "out"))
                (src (assoc-ref %build-inputs "source"))
                (tar (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin"))
                (patchelf (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
                (interp (string-append (assoc-ref %build-inputs "glibc") "/lib/ld-linux-x86-64.so.2")))
           (setenv "PATH" gzip)
           (mkdir-p (string-append out "/bin"))
           (invoke tar "-xzf" src "-C" (string-append out "/bin"))
           (invoke patchelf "--set-interpreter" interp (string-append out "/bin/ht"))))))
    (home-page "https://github.com/montanaflynn/headless-terminal")
    (synopsis "Puppeteer for terminal UIs")
    (description "Headless terminal is a puppeteer for terminal UIs. Drive vim, emacs, htop, nethack, or any other interactive TUI from a CLI (or an AI agent). Spawn the program in a background session, send keystrokes, snapshot the screen, and watch the whole thing live from another shell.")
    (license license:expat)))
