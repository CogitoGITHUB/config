(define-module (substrate user-space root desktop hyprland)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system meson)
  #:use-module (guix gexp)
  #:use-module (gnu packages base)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages engineering)
  #:use-module (gnu packages freedesktop)
  #:use-module ((gnu packages gcc) #:select (gcc-15))
  #:use-module (gnu packages gl)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages image)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages regex)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xdisorg)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (lua-5.5 hyprutils hyprgraphics wayland wayland-protocols hyprland))

(define-public lua-5.5
  (package
    (name "lua")
    (version "5.5.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://www.lua.org/ftp/lua-" version ".tar.gz"))
              (sha256
               (base32 "0gcbsr00difm2s82pflxg28zcnjka9048lncbfvwl1fhpcmw7k2p"))))
    (build-system gnu-build-system)
    (inputs (list readline))
    (arguments
     (list #:test-target "test"
           #:make-flags #~(list "MYCFLAGS=-fPIC -DLUA_DL_DLOPEN"
                                "CC=gcc"
                                "linux")
           #:phases
           #~(modify-phases %standard-phases
               (delete 'configure)
               (add-after 'install 'install-pkgconfig
                 (lambda* (#:key outputs #:allow-other-keys)
                   (let* ((out (assoc-ref outputs "out"))
                          (pc  (string-append out "/lib/pkgconfig")))
                     (mkdir-p pc)
                     (call-with-output-file (string-append pc "/lua5.5.pc")
                       (lambda (port)
                         (format port "prefix=~a\nexec_prefix=${prefix}\nlibdir=${exec_prefix}/lib\nincludedir=${prefix}/include\nName: Lua\nDescription: Lua scripting language\nVersion: ~a\nLibs: -L${libdir} -llua\nCflags: -I${includedir}\n"
                                 out #$version))))))
               (replace 'install
                 (lambda* (#:key outputs #:allow-other-keys)
                   (let ((out (assoc-ref outputs "out")))
                     (invoke "make" "install"
                             (string-append "INSTALL_TOP=" out)
                             (string-append "INSTALL_MAN=" out "/share/man/man1"))))))))
    (home-page "https://www.lua.org/")
    (synopsis "Embeddable scripting language")
    (description "Lua 5.5 scripting language.")
    (license license:x11)))

(define-public hyprutils
  (package
    (name "hyprutils")
    (version "0.13.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/hyprwm/hyprutils/archive/refs/tags/v"
                    version ".tar.gz"))
              (sha256 (base32 "1pmfd5n25si1q02wndnfjiskajz5mc6di5pb4i5advjx20kf03j8"))))
    (build-system cmake-build-system)
    (arguments (list #:tests? #f))
    (native-inputs (list pkg-config))
    (inputs (list pixman))
    (propagated-inputs (list gcc-15))
    (home-page "https://github.com/hyprwm/hyprutils")
    (synopsis "C++ library for utilities used across Hyprland ecosystem")
    (description "Hyprutils is a C++ library for utilities used across the Hyprland ecosystem.")
    (license license:bsd-3)))

(define-public hyprgraphics
  (package
    (name "hyprgraphics")
    (version "0.5.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/hyprwm/hyprgraphics/archive/refs/tags/v"
                    version ".tar.gz"))
              (sha256 (base32 "0x1v06nc4qxwjay0c7dvpb2bziscg8nn2nklslnr4d98hynwl7l6"))))
    (build-system cmake-build-system)
    (arguments (list #:tests? #f))
    (native-inputs (list gcc-15 pkg-config))
    (inputs (list cairo
                  hyprutils
                  libjpeg-turbo
                  libjxl
                  librsvg
                  libwebp
                  mesa
                  pango
                  pixman
                  spng))
    (home-page "https://wiki.hypr.land/Hypr-Ecosystem/hyprgraphics/")
    (synopsis "Hyprland graphics/resource utilities")
    (description "Hyprgraphics is a small C++ library with graphics/resource related utilities.")
    (license license:bsd-3)))

(define-public wayland
  (package
    (name "wayland")
    (version "1.25.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://gitlab.freedesktop.org/" name
                                  "/" name "/-/releases/" version "/downloads/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "00qzm9pk1x8m5wi2gkzw4by1l6p44ybj83v0h1v1gwyzmx0g0rf0"))))
    (build-system meson-build-system)
    (arguments
     (list #:configure-flags #~'("-Ddocumentation=false")
           #:tests? #f))
    (native-inputs (list pkg-config python))
    (inputs (list expat libxml2))
    (propagated-inputs (list libffi))
    (home-page "https://wayland.freedesktop.org/")
    (synopsis "Core Wayland window system code and protocol")
    (description "Wayland is a project to define a protocol for a compositor to
talk to its clients as well as a library implementation of the protocol.")
    (license license:expat)))

(define-public wayland-protocols
  (package
    (name "wayland-protocols")
    (version "1.49")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/"
                    version "/downloads/wayland-protocols-" version ".tar.xz"))
              (sha256
               (base32
                "050b4jny5pkylx79fpcki9hzzy8f9xvf8k4brrxgyv9djis8yk7c"))))
    (build-system meson-build-system)
    (inputs (list wayland))
    (native-inputs (list pkg-config python))
    (synopsis "Wayland protocols")
    (description "Wayland-Protocols contains Wayland protocols that add
functionality not available in the Wayland core protocol.")
    (home-page "https://wayland.freedesktop.org")
    (license license:expat)))

(define-public hyprland
  (package
    (name "hyprland")
    (version "0.56.0")
    (source (origin
               (method url-fetch)
               (uri (string-append "https://github.com/hyprwm/Hyprland"
                                   "/releases/download/v" version
                                   "/source-v" version ".tar.gz"))
               (modules '((guix build utils)))
               (snippet
                '(begin
                   (substitute* "CMakeLists.txt"
                     (("^add_subdirectory\\(hyprpm\\).*") ""))
                   (for-each delete-file-recursively
                             '("hyprpm" "subprojects"))))
               (sha256
                (base32
                 "1349s29zkj2mr8s2hq7ls2226i7fnm88mkfd46bb9jw9m6rs691y"))))
     (build-system cmake-build-system)
    (arguments
     (list #:tests? #f
           #:configure-flags #~'("-DNO_HYPRPM=True")
           #:phases
           #~(modify-phases %standard-phases
      (add-after 'unpack 'fix-path
                    (lambda* (#:key inputs #:allow-other-keys)
                      (call-with-output-file "src/compat.hpp"
                        (lambda (port)
                          (format port "#pragma once
#include <hyprutils/memory/SharedPtr.hpp>
namespace Hyprutils::Memory {
template<typename T, typename U>
CSharedPointer<T> staticPointerCast(const CSharedPointer<U>& ref) {
    if (!ref) return nullptr;
    T* newPtr = static_cast<T*>(sc<U*>(ref.impl_->getData()));
    if (!newPtr) return nullptr;
    return CSharedPointer<T>(ref.impl_, newPtr);
}
}
")))
                      (invoke "sed" "-i" "s/std::string_view/std::string/g" "hyprctl/src/main.cpp")
                      (invoke "sed" "-E" "-i"
                         "s/std::ranges::starts_with\\(([^,]+), ([^)]+)\\)/std::equal(\\2.begin(), \\2.end(), \\1.begin())/g"
                        "src/helpers/MiscFunctions.cpp")
                      (invoke "sed" "-i" "s/dynamicPointerCast<CWindow>(v)/staticPointerCast<CWindow>(v)/" "src/desktop/view/Window.cpp")
                       (invoke "sed" "-i" "/^  VERSION ${VER})/a add_compile_options(-include src/compat.hpp)" "CMakeLists.txt")
                      (substitute* "src/xwayland/Server.cpp"
                        (("Xwayland( \\{\\})" _ suffix)
                         (string-append
                          (search-input-file inputs "bin/Xwayland")
                          suffix)))
                      (substitute* (find-files "src" "\\.cpp$")
                        (("/usr/local(/bin/Hyprland)" _ path)
                         (string-append #$output path))
                        (("/usr") #$output)
                        (("\\<(addr2line|cat|lspci|nm)\\>" cmd)
                         (search-input-file
                          inputs (string-append "bin/" cmd))))
                      (substitute* '("src/Compositor.cpp"
                                     "src/xwayland/XWayland.cpp"
                                     "src/managers/VersionKeeperManager.cpp")
                        (("!NFsUtils::executableExistsInPath.*\".") "false")
                        (("hyprland-update-screen" cmd)
                         (search-input-file inputs (in-vicinity "bin" cmd)))))))))
    (native-inputs
     (list gcc-15
           hyprwayland-scanner
           lua-5.5
           python
           (module-ref (resolve-interface
                        '(gnu packages commencement))
                       'ld-wrapper)
           pkg-config))
    (inputs
      (list aquamarine
            binutils
            cairo
            glslang
            spirv-tools
            glaze
            hyprcursor
            hyprland-protocols
            hyprland-guiutils
            hyprlang
            hyprwire
            libei
            libinput
            readline
            libxcursor
            libxkbcommon
            mesa
            muparser
            pango
            pciutils
            re2
            udis86
            wayland
            wayland-protocols
            xcb-util-errors
            xcb-util-wm
            xorg-server-xwayland))
    (propagated-inputs
     (list hyprgraphics hyprutils lcms))
    (home-page "https://hypr.land/")
    (synopsis "Dynamic tiling Wayland compositor")
    (description "Hyprland is a dynamic tiling Wayland compositor.")
    (properties '((upstream-name . "source")))
    (license license:bsd-3)))
