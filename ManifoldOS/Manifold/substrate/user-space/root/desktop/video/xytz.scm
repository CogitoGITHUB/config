(define-module (substrate user-space root desktop video xytz)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (xytz))

(define-public xytz
  (package
    (name "xytz")
    (version "0.8.7")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/xdagiz/xytz/releases/download/v" version "/xytz-v" version "-linux-amd64.tar.gz"))
              (sha256
               (base32
                "001x94zx3iyqi4bq9q92lnrliji19fprhyf96xgv11mq8iydhszm"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("xytz" "bin/"))))
    (synopsis "Beautiful YouTube downloader/player TUI")
    (description "xytz is a terminal-based YouTube downloader and player with interactive search, channel browsing, playlist support, format selection, batch downloads, and video playback with mpv.")
    (home-page "https://github.com/xdagiz/xytz")
    (license license:expat)))
