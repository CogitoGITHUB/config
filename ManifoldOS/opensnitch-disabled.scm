(define-module (substrate user-space root security opensnitch)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix build-system go)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages golang-build)
  #:use-module (gnu packages golang-check)
  #:use-module (gnu packages golang-crypto)
  #:use-module (gnu packages golang-web)
  #:use-module (gnu packages golang-xyz)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages protobuf)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages rpc)
  #:use-module (gnu packages serialization)
  #:export (opensnitch-daemon opensnitch-ui))

;; Simplified from gnu/packages/networking.scm
(define-public opensnitch-daemon
  (package
    (name "opensnitch-daemon")
    (version "1.8.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/evilsocket/opensnitch")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1bvpv4n3a4q8pg3wj9cv7fyqs7l2d1cw96g5j7lmpsq267c62gh7"))))
    (build-system go-build-system)
    (arguments
     (list
      #:install-source? #f
      #:import-path "github.com/evilsocket/opensnitch/daemon"
      #:unpack-path "github.com/evilsocket/opensnitch"
      #:tests? #f))
    (inputs (list libnetfilter-queue libnfnetlink libvarlink))
    (home-page "https://github.com/evilsocket/opensnitch")
    (synopsis "Interactive application firewall daemon")
    (description
     "OpenSnitch is an application-level firewall that gives you granular
control over outbound network connections on your system.")
    (license license:gpl3+)))

(define-public opensnitch-ui
  (package
    (name "opensnitch-ui")
    (version "1.8.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/evilsocket/opensnitch")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1bvpv4n3a4q8pg3wj9cv7fyqs7l2d1cw96g5j7lmpsq267c62gh7"))))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f))
    (inputs (list python-grpcio-tools
                  python-notify2
                  python-pyasn1
                  python-pyinotify
                  python-pyqt-6
                  python-protobuf
                  python-requests
                  python-slugify
                  qtbase
                  qtsvg
                  qtwayland))
    (home-page "https://github.com/evilsocket/opensnitch")
    (synopsis "UI for opensnitch")
    (description
     "Graphical user interface for OpenSnitch firewall daemon.")
    (license license:gpl3+)))
