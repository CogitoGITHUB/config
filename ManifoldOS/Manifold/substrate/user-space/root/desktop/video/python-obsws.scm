(define-module (substrate user-space root desktop video python-obsws)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system pyproject)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages python-web)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (python-obsws))

(define-public python-obsws
  (package
    (name "python-obsws")
    (version "1.8.0")
    (source
      (origin
        (method git-fetch)
        (uri (git-reference
              (url "https://github.com/aatikturk/obsws-python")
              (commit "f70583d7ca250c1f3a0df768d3cfd41663a6023b")))
        (file-name (git-file-name name version))
        (sha256
          (base32 "15rigjxsmwcq4jw8md3lmfx48pa3aar67ypiw4la1rzzd5525clj"))))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f))
    (native-inputs (list python-hatchling))
    (propagated-inputs
      (list python-tomli python-websocket-client))
    (home-page "https://github.com/aatikturk/obsws-python")
    (synopsis "Python SDK for OBS Studio WebSocket v5.0")
    (description
     "A Python SDK for OBS Studio WebSocket v5.0. Supports scene management,
source toggling, recording and streaming control, and more.")
    (license license:gpl3)))
