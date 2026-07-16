(define-module (substrate user-space root shell fetch fastfetch)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xdisorg)
  #:use-module (substrate user-space root shell archive unzip)
  #:use-module (substrate user-space root shell archive zlib)
  #:use-module (gnu packages c)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages networking)
  #:export (fastfetch))

(define-public fastfetch-minimal
  (package
    (name "fastfetch-minimal")
    (version "2.60.0")
    (source
      (origin
        (method git-fetch)
        (uri (git-reference
              (url "https://github.com/fastfetch-cli/fastfetch")
              (commit version)))
        (file-name (git-file-name name version))
        (sha256
          (base32 "089577qgxd63zqzd00fz381bfpmj6pwlmy2zfan9r6gbm1jvj4i8"))
        (modules '((guix build utils)))
        (snippet '(begin
                    (delete-file-recursively "src/3rdparty")
                    (substitute* "src/modules/logo/logo.c"
                      (("\"3rdparty/yyjson/yyjson.h\"")
                       "<yyjson.h>"))))))
    (build-system cmake-build-system)
    (arguments
      (list
        #:configure-flags #~(list "-DENABLE_SYSTEM_YYJSON=ON"
                                  "-DBUILD_FLASHFETCH=OFF"
                                  "-DBUILD_TESTS=ON"
                                  "-DINSTALL_LICENSE=OFF")))
    (inputs (list yyjson))
    (native-inputs (list pkg-config python-minimal))
    (home-page "https://github.com/fastfetch-cli/fastfetch")
    (synopsis "Display system information in a stylized manner")
    (description
      "fastfetch is a performant way to retrieve system information.")
    (license license:expat)))

(define-public fastfetch
  (package
    (inherit fastfetch-minimal)
    (name "fastfetch")
    (inputs (list bash clang curl dbus libxcb libxkbcommon
                   yyjson zlib wayland
                   fastfetch-minimal))
    (arguments
      (list #:configure-flags
            #~(list "-DENABLE_SYSTEM_YYJSON=ON"
                    "-DBUILD_TESTS=ON"
                    "-DINSTALL_LICENSE=OFF")))))
