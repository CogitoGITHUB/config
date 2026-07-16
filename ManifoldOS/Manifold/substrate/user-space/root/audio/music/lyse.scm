(define-module (substrate user-space root audio music lyse)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages python)
  #:use-module (gnu packages music)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (lyse))

(define-public lyse
  (package
    (name "lyse")
    (version "3.0.0")
    (source
      (origin
        (method url-fetch)
        (uri "https://raw.githubusercontent.com/snoowfall/lyse/main/lyse.py")
        (sha256
          (base32 "0lclx8bxncsn5dj3pi8wpqyykhknacdbi7qhn4m6jlxdlal183sk"))))
    (build-system trivial-build-system)
    (inputs
      (list python python-wrapper playerctl))
    (arguments
      (list #:modules (quote ((guix build utils)))
            #:builder
        (quasiquote (begin
          (use-modules (guix build utils))
          (let* ((out (assoc-ref %outputs "out"))
                 (src (assoc-ref %build-inputs "source"))
                 (python (string-append (assoc-ref %build-inputs "python") "/bin/python3")))
            (mkdir-p (string-append out "/bin"))
            (copy-file src (string-append out "/bin/lyse"))
            (substitute* (string-append out "/bin/lyse")
              (("/usr/bin/env python3") python))
            (chmod (string-append out "/bin/lyse") #o555))))))
    (home-page "https://github.com/snoowfall/lyse")
    (synopsis "Realtime TUI lyrics for your terminal")
    (description
     "Lyse displays real-time synced lyrics for whatever song is playing,
using playerctl to detect the current track and lrclib.net for lyrics.")
    (license license:agpl3+)))
