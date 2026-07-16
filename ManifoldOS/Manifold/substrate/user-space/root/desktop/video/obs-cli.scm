(define-module (substrate user-space root desktop video obs-cli)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system pyproject)
  #:use-module (gnu packages python-build)
  #:use-module (substrate user-space root desktop video python-obsws)
  #:use-module (gnu packages python-xyz)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (obs-cli))

(define-public obs-cli
  (package
    (name "obs-cli")
    (version "0.9.5")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/pschmitt/obs-cli")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "10mc0635z7rgxnx6hq67298sjzbsfd9v1fd8kplfjyg4qiddvhks"))))
    (build-system pyproject-build-system)
    (arguments
     (list #:tests? #f))
    (propagated-inputs (list python-obsws python-rich python-rich-argparse))
    (native-inputs (list python-setuptools python-setuptools-scm))
    (home-page "https://github.com/pschmitt/obs-cli")
    (synopsis "Command-line interface for controlling OBS Studio")
    (description
     "OBS CLI is a command-line interface for controlling OBS Studio via
the obs-websocket v5 API.  It supports scene management, source toggling,
recording/streaming control, virtual camera, and more.")
    (license license:gpl3)))
