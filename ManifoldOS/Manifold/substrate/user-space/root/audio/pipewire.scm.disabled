(define-module (substrate user-space root audio pipewire)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix build-system meson)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages avahi)
  ;; Disabled - bluetooth module not available
;; #:use-module (gnu packages bluetooth)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages docbook)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gstreamer)
  ;; Disabled - jack module not available
  ;; #:use-module (gnu packages jack)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages man)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages video)
  #:use-module (gnu packages vulkan)
  #:export (pipewire wireplumber))

(define-public pipewire
  (package
    (name "pipewire")
    (version "1.5.85")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://gitlab.freedesktop.org/pipewire/pipewire")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1nd74wjy16bw8ng00acc26rakpqabcq1z64h23w97i18pb7z64xq"))))
    (build-system meson-build-system)
    (arguments
     (list
      #:configure-flags
      #~(list (string-append "-Dudevrulesdir=" #$output "/lib/udev/rules.d")
              "-Dman=enabled"
              "-Drlimits-install=false"
              "-Dsession-managers=[]"
              "-Dsysconfdir=/etc"
              "-Dlibsystemd=disabled"
              "-Db_asneeded=false")))
    (native-inputs
     (list `(,glib "bin")
           pkg-config
           doxygen
           python
           python-docutils))
    (inputs (list alsa-lib
                  avahi
                  bluez
                  dbus
                  eudev
                  ffmpeg
                  gst-plugins-base
                  gstreamer
                  jack-2
                  ldacbt
                  libcamera
                  libdrm
                  libfdk
                  libfreeaptx
                  libsndfile
                  libusb
                  openssl
                  libva
                  pulseaudio
                  readline
                  sbc
                  vulkan-headers
                  vulkan-loader
                  webrtc-audio-processing))
    (home-page "https://pipewire.org/")
    (synopsis "Server and user space API to deal with multimedia pipelines")
    (description "PipeWire is a project that aims to greatly improve handling
of audio and video under Linux.")
    (license license:lgpl2.0+)))

(define-public wireplumber
  (package
    (name "wireplumber")
    (version "0.5.12")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://gitlab.freedesktop.org/pipewire/wireplumber.git")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1dljz669ywy1lvvn0jh14ymynmbii45q5vay71zajpcg31249dyw"))))
    (build-system meson-build-system)
    (arguments
     `(#:configure-flags '("-Dsystemd=disabled"
                           "-Dsystem-lua=true")))
    (native-inputs
     (list `(,glib "bin")
           pkg-config python-minimal))
    (inputs (list dbus elogind glib lua pipewire))
    (home-page "https://gitlab.freedesktop.org/pipewire/wireplumber")
    (synopsis "Session / policy manager implementation for PipeWire")
    (description "WirePlumber is a modular session / policy manager for PipeWire.")
    (license license:expat)))
