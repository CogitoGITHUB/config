(define-module (substrate user-space root desktop 3d blender)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages bash)
  #:use-module (guix build-system trivial)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (blender))

(define-public blender
  (package
    (name "blender")
    (version "5.1.2")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://download.blender.org/release/Blender"
              (version-major+minor version)
              "/blender-" version "-linux-x64.tar.xz"))
        (sha256
          (base32 "1yw5l9i2d14m4abz8ngsnmhn59q3f53fgk4bd6drg0q1ymav7k5a"))))
    (build-system trivial-build-system)
    (inputs
      (list tar xz patchelf glibc (list gcc "lib")
            libx11 libxrender libxfixes libxi libxkbcommon
            libsm libice mesa wayland bash))
    (arguments
      (list #:modules (quote ((guix build utils)))
            #:builder
        (quasiquote (begin
          (use-modules (guix build utils))
          (let* ((out (assoc-ref %outputs "out"))
                 (src (assoc-ref %build-inputs "source"))
                 (bash (assoc-ref %build-inputs "bash"))
                 (tar (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                 (xz (string-append (assoc-ref %build-inputs "xz") "/bin/xz"))
                 (patchelf (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
                 (glibc (assoc-ref %build-inputs "glibc"))
                 (gcc (assoc-ref %build-inputs "gcc"))
                 (libx11 (assoc-ref %build-inputs "libx11"))
                 (libxrender (assoc-ref %build-inputs "libxrender"))
                 (libxfixes (assoc-ref %build-inputs "libxfixes"))
                 (libxi (assoc-ref %build-inputs "libxi"))
                 (libxkbcommon (assoc-ref %build-inputs "libxkbcommon"))
                 (libsm (assoc-ref %build-inputs "libsm"))
                 (libice (assoc-ref %build-inputs "libice"))
                  (mesa (assoc-ref %build-inputs "mesa"))
                  (wayland (assoc-ref %build-inputs "wayland"))
                  (librpath (string-append
                              (string-append gcc "/lib:")
                              libx11 "/lib:"
                              libxrender "/lib:"
                              libxfixes "/lib:"
                              libxi "/lib:"
                              libxkbcommon "/lib:"
                              libsm "/lib:"
                              libice "/lib:"
                              mesa "/lib:"
                              wayland "/lib")))
            (setenv "PATH" (dirname xz))
            (mkdir-p (string-append out "/bin"))
            (invoke tar "-xJf" src
                    "--strip-components=1"
                    "-C" (string-append out "/bin"))
            (invoke patchelf
                    "--set-interpreter"
                    (string-append glibc "/lib/ld-linux-x86-64.so.2")
                    "--set-rpath"
                    (string-append "$ORIGIN/lib:" librpath)
                    (string-append out "/bin/blender"))
            (rename-file (string-append out "/bin/blender")
                         (string-append out "/bin/.blender-real"))
            (call-with-output-file (string-append out "/bin/blender")
              (lambda (port)
                (format port "#!~a/bin/sh\nexport LD_LIBRARY_PATH=\"~a:$LD_LIBRARY_PATH\"\nexec \"~a/bin/.blender-real\" \"$@\"\n"
                        bash librpath out)))
            (chmod (string-append out "/bin/blender") #o555))))))
    (home-page "https://www.blender.org")
    (synopsis "3D creation suite")
    (description
     "Blender is the free and open source 3D creation suite. It supports the
entirety of the 3D pipeline - modeling, rigging, animation, simulation,
rendering, compositing, motion tracking and video editing.")
    (license license:gpl3+)))
