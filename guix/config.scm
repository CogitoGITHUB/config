(use-modules (gnu)
             (gnu services shepherd)
             (gnu services networking)
             (guix packages)
             (guix download)
             (guix git-download)
             (guix build-system trivial)
             (guix build-system gnu)
             (guix build-system cmake)
             (gnu packages ssh)
             (guix build-system emacs)
             (guix gexp)
             (gnu packages base)
             (gnu packages compression)
             (gnu packages shells)
             (gnu packages version-control)
             (gnu packages emacs)
             (gnu packages web-browsers)
             (gnu packages shellutils)
             (gnu packages terminals)
             (gnu packages nushell)
             (gnu packages rust-apps)
             (gnu packages wm)
             (gnu packages elf)
             (gnu packages gcc)
             (gnu packages pkg-config)
             (gnu packages gl)
             (gnu packages gtk)
             (gnu packages xorg)
             (gnu packages xdisorg)
             (gnu packages freedesktop)
             (gnu packages cpp)
             (gnu packages engineering)
             (gnu packages maths)
             (gnu packages pciutils)
             (gnu packages regex)
             (gnu packages vulkan)
             (gnu packages image)
             (gnu packages ghostscript)
             (gnu packages readline)
             (gnu packages python)
             (guix build-system cargo)
             (gnu packages gnome)
             (guix licenses)
             (gnu packages emacs-xyz)
             (gnu packages emacs-build))
(use-service-modules networking ssh desktop xorg)
(define unzip (@ (gnu packages compression) unzip))
(define patchelf (@ (gnu packages elf) patchelf))


(define-public television
  (package
    (name "television")
    (version "0.15.4")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/alexpasmantier/television/releases/download/" version
              "/tv-" version "-x86_64-unknown-linux-musl.tar.gz"))
        (sha256 (base32 "0in9wc8dnv62pbnmmx7rzham044wl10mws8mmgfvakajljxgdb4w"))))
    (build-system trivial-build-system)
    (inputs (list tar gzip))
    (arguments
      (list #:modules '((guix build utils))
            #:builder
        `(begin
           (use-modules (guix build utils))
           (let* ((out (assoc-ref %outputs "out"))
                  (src (assoc-ref %build-inputs "source"))
                  (tar (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                  (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin")))
             (setenv "PATH" gzip)
             (mkdir-p (string-append out "/bin"))
             (invoke tar "-xzf" src
                     "--strip-components=1"
                     "-C" (string-append out "/bin")
                     (string-append "tv-" "0.15.4" "-x86_64-unknown-linux-musl/tv"))))))
    (home-page "https://github.com/alexpasmantier/television")
    (synopsis "Fast fuzzy finder TUI")
    (description "Television is a fast fuzzy finder for the terminal.")
(license (@ (guix licenses) expat))))

(define kanata
  (package
    (name "kanata")
    (version "1.11.0")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/jtroo/kanata/releases/download/v1.11.0/linux-binaries-x64.zip")
       (sha256 (base32 "1qmlb5a54hgri65c8v19hd6jshsvss7rkwxc5b67iw67njpk9xnr"))))
    (build-system trivial-build-system)
    (inputs (list unzip patchelf glibc `(,gcc "lib")))
    (arguments
     (list #:modules '((guix build utils))
           #:builder
           #~(begin
               (use-modules (guix build utils))
               (let* ((out      (assoc-ref %outputs "out"))
                      (src      (assoc-ref %build-inputs "source"))
                      (unzip    (string-append (assoc-ref %build-inputs "unzip") "/bin/unzip"))
                      (patchelf (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
                      (glibc    (assoc-ref %build-inputs "glibc"))
                      (gcc-lib  (assoc-ref %build-inputs "gcc"))
                      (interp   (string-append glibc "/lib/ld-linux-x86-64.so.2"))
                      (rpath    (string-append gcc-lib "/lib")))
                 (mkdir-p (string-append out "/bin"))
                 (invoke unzip "-j" src "kanata_linux_x64" "-d" (string-append out "/bin"))
                 (rename-file (string-append out "/bin/kanata_linux_x64")
                              (string-append out "/bin/kanata"))
                 (invoke patchelf "--set-interpreter" interp
                         "--set-rpath" rpath
                         (string-append out "/bin/kanata"))))))
    (home-page "https://github.com/jtroo/kanata")
    (synopsis "Keyboard remapper")
    (description "Kanata is a keyboard remapper for Linux.")
    (license (@ (guix licenses) lgpl3))))
(define seatd (@ (gnu packages admin) seatd))
(define kanata-service
  (simple-service 'kanata
                  shepherd-root-service-type
                  (list (shepherd-service
                         (provision '(kanata))
                         (requirement '(user-processes))
                         (start #~(make-forkexec-constructor
                                   (list #$(file-append kanata "/bin/kanata")
                                         "--cfg" "/home/aoeu/.config/kanata/kanata.kbd")
                                   #:log-file "/var/log/kanata.log"))
                         (stop #~(make-kill-destructor))
                         (respawn? #t)))))

(define atuin
  (package
    (name "atuin")
    (version "18.13.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/atuinsh/atuin/releases/download/v" version
             "/atuin-x86_64-unknown-linux-musl.tar.gz"))
       (sha256 (base32 "0gigapvzk2pbiw76dkrdslll96isjgq36camhs034vc1mnnjww8r"))))
    (build-system trivial-build-system)
    (inputs (list tar gzip))
    (arguments
     (list #:modules '((guix build utils))
           #:builder
           #~(begin
               (use-modules (guix build utils))
               (let* ((out  (assoc-ref %outputs "out"))
                      (src  (assoc-ref %build-inputs "source"))
                      (tar  (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                      (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin")))
                 (setenv "PATH" gzip)
                 (mkdir-p (string-append out "/bin"))
                 (invoke tar "-xzf" src
                         "--strip-components=1"
                         "-C" (string-append out "/bin")
                         "atuin-x86_64-unknown-linux-musl/atuin")))))
    (home-page "https://atuin.sh")
    (synopsis "Shell history manager")
    (description "Atuin replaces your shell history with a SQLite database.")
    (license (@ (guix licenses) asl2.0))))
(define zellij
  (package
    (name "zellij")
    (version "0.44.0")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/zellij-org/zellij/releases/download/v" version
              "/zellij-x86_64-unknown-linux-musl.tar.gz"))
        (sha256 (base32 "1cxd8xw5kssknyrd3l4znvb4sm1jvaj8qbl8rkb3mhcfr581v63y"))))
    (build-system trivial-build-system)
    (inputs (list tar gzip))
    (arguments
      (list #:modules (quote ((guix build utils)))
            #:builder
        (quasiquote (begin
          (use-modules (guix build utils))
          (let* ((out (assoc-ref %outputs "out"))
                 (src (assoc-ref %build-inputs "source"))
                 (tar (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                 (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin")))
            (setenv "PATH" gzip)
            (mkdir-p (string-append out "/bin"))
            (invoke tar "-xzf" src "-C" (string-append out "/bin")))))))
    (home-page "https://zellij.dev")
    (synopsis "Terminal workspace")
    (description "Zellij is a terminal workspace with multiplexed terminals.")
    (license (@ (guix licenses) asl2.0))))
(define tailscale
  (package
    (name "tailscale")
    (version "1.96.2")
    (source
     (origin
       (method url-fetch)
       (uri "https://pkgs.tailscale.com/stable/tailscale_1.96.2_amd64.tgz")
       (sha256 (base32 "00blgy5j5x0zp45xvy421mpkg5bdvzf2gnbywil3rnspxhysz8na"))))
    (build-system trivial-build-system)
    (inputs (list tar gzip))
    (arguments
     (list #:modules '((guix build utils))
           #:builder
           #~(begin
               (use-modules (guix build utils))
               (let* ((out  (assoc-ref %outputs "out"))
                      (src  (assoc-ref %build-inputs "source"))
                      (tar  (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                      (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin")))
                 (setenv "PATH" gzip)
                 (mkdir-p (string-append out "/bin"))
                 (invoke tar "-xzf" src
                         "--strip-components=1"
                         "-C" (string-append out "/bin")
                         "tailscale_1.96.2_amd64/tailscale"
                         "tailscale_1.96.2_amd64/tailscaled")))))
    (home-page "https://tailscale.com/")
    (synopsis "Tailscale VPN")
    (description "Tailscale is a zero-config VPN.")
    (license (@ (guix licenses) bsd-3))))
(define tailscale-state-dir "/var/lib/tailscale")
(define tailscale-run-dir   "/var/run/tailscale")
(define tailscale-socket    "/var/run/tailscale/tailscaled.sock")
(define tailscale-activation
  (with-imported-modules '((guix build utils))
    #~(begin
        (use-modules (guix build utils))
        (mkdir-p #$tailscale-state-dir)
        (mkdir-p #$tailscale-run-dir)
        (chmod #$tailscale-state-dir #o700)
        (chmod #$tailscale-run-dir   #o755))))
(define (tailscale-shepherd-service config)
  (let ((tailscaled (file-append tailscale "/bin/tailscaled")))
    (list
     (shepherd-service
      (documentation "Run the Tailscale daemon (tailscaled)")
      (provision '(tailscaled tailscale))
      (requirement '(user-processes networking))
      (start #~(make-forkexec-constructor
                (list #$tailscaled
                      "--statedir" #$tailscale-state-dir
                      "--socket"   #$tailscale-socket
                      "--port"     "41641"
                      "--verbose"  "1")
                #:log-file "/var/log/tailscaled.log"))
      (stop  #~(make-kill-destructor))
      (respawn? #t)))))
(define tailscaled-service-type
  (service-type
   (name 'tailscaled)
   (extensions
    (list
     (service-extension shepherd-root-service-type
                        tailscale-shepherd-service)
     (service-extension activation-service-type
                        (const tailscale-activation))))
   (default-value #f)
   (description "Run the Tailscale daemon.")))
(define github-cli
  (package
    (name "github-cli")
    (version "2.63.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/cli/cli/releases/download/v" version
             "/gh_" version "_linux_amd64.tar.gz"))
       (sha256 (base32 "007d5lkh02wsq6g0z7d24f4hg2d2hyvx5ibgfkxhbc4wl8fdnbwi"))))
    (build-system trivial-build-system)
    (inputs (list tar gzip))
    (arguments
     (list #:modules '((guix build utils))
           #:builder
           #~(begin
               (use-modules (guix build utils))
               (let* ((out  (assoc-ref %outputs "out"))
                      (src  (assoc-ref %build-inputs "source"))
                      (tar  (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                      (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin")))
                 (setenv "PATH" gzip)
                 (mkdir-p (string-append out "/bin"))
                 (invoke tar "-xzf" src
                         "--strip-components=2"
                         "-C" (string-append out "/bin")
                         "gh_2.63.2_linux_amd64/bin/gh")))))
    (home-page "https://cli.github.com/")
    (synopsis "GitHub CLI tool")
    (description "gh is the official GitHub command line tool.")
    (license (@ (guix licenses) asl2.0))))
(define opencode
  (package
    (name "opencode")
    (version "1.14.17")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/anomalyco/opencode/releases/download/v" version
             "/opencode-linux-x64.tar.gz"))
       (sha256 (base32 "1mj1h3ikk1c9mz62d6p4wd905wm6ld9amhck9kp2hn8abr5vgrys"))))
    (build-system trivial-build-system)
    (inputs (list tar gzip patchelf glibc `(,gcc "lib")))
    (propagated-inputs (list glibc))
    (arguments
     (list #:modules '((guix build utils))
           #:builder
           #~(begin
               (use-modules (guix build utils))
               (let* ((out          (assoc-ref %outputs "out"))
                      (src          (assoc-ref %build-inputs "source"))
                      (tar          (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                      (gzip         (string-append (assoc-ref %build-inputs "gzip") "/bin"))
                      (patchelf     (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
                      (glibc        (assoc-ref %build-inputs "glibc"))
                      (gcc-lib      (assoc-ref %build-inputs "gcc"))
                      (interp       (string-append glibc "/lib/ld-linux-x86-64.so.2"))
                      (rpath        (string-append (assoc-ref %build-inputs "glibc") "/lib:" gcc-lib "/lib"))
                      (opencode-real (string-append out "/bin/opencode-real"))
                      (opencode-bin  (string-append out "/bin/opencode")))
                 (setenv "PATH" gzip)
                 (mkdir-p (string-append out "/bin"))
                 (invoke tar "-xzf" src "-C" (string-append out "/bin"))
                 (rename-file opencode-bin opencode-real)
                 (invoke patchelf "--set-interpreter" interp
                         "--set-rpath" rpath
                         opencode-real)
                 (call-with-output-file opencode-bin
                   (lambda (port)
                     (format port
                             "#!/bin/sh\nLD_LIBRARY_PATH=~a:$LD_LIBRARY_PATH OPENCODE_EXPERIMENTAL_MARKDOWN=0 exec ~a \"$@\"\n"
                             rpath
                             opencode-real)))
                 (chmod opencode-bin #o555)))))
    (home-page "https://opencode.ai")
    (synopsis "AI coding agent for the terminal")
    (description "OpenCode is an open source AI coding agent built for the terminal.")
    (license (@ (guix licenses) expat))))
(define lua-5.5
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
     (list #:modules '((guix build gnu-build-system)
                       (guix build utils)
                       (srfi srfi-1))
           #:test-target "test"
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
                         (format port "\
prefix=~a
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include
Name: Lua
Description: Lua scripting language
Version: ~a
Libs: -L${libdir} -llua
Cflags: -I${includedir}
" out #$version))))))
               (replace 'install
                 (lambda* (#:key outputs #:allow-other-keys)
                   (let ((out (assoc-ref outputs "out")))
                     (invoke "make" "install"
                             (string-append "INSTALL_TOP=" out)
                             (string-append "INSTALL_MAN=" out "/share/man/man1"))))))))
    (home-page "https://www.lua.org/")
    (synopsis "Embeddable scripting language")
    (description "Lua 5.5 scripting language.")
    (license (@ (guix licenses) x11))))
(define hyprutils
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
    (license (@ (guix licenses) bsd-3))))
(define hyprgraphics
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
    (license (@ (guix licenses) bsd-3))))
(define hyprland
  (package
    (name "hyprland")
    (version "0.55.0")
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
                            '("hyprpm"
                              "subprojects"))))
              (sha256
               (base32
                "1h6avxwz858ll133zbmqbplws2scp6hi1ig0s6bwjywyayss1q9b"))))
    (build-system cmake-build-system)
    (arguments
     (list #:tests? #f
           #:configure-flags #~'("-DNO_HYPRPM=True")
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'fix-path
                 (lambda* (#:key inputs #:allow-other-keys)
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
           (@ (gnu packages freedesktop) libinput)
           libxcursor
           libxkbcommon
           mesa
           muparser
           pango
           pciutils
           re2-next
           udis86
           (@ (gnu packages freedesktop) wayland)
           (@ (gnu packages freedesktop) wayland-protocols)
           xcb-util-errors
           xcb-util-wm
           xorg-server-xwayland))
    (propagated-inputs
     (list hyprgraphics
           hyprutils
           lcms))
    (home-page "https://hypr.land/")
    (synopsis "Dynamic tiling Wayland compositor")
    (description
     "Hyprland is a dynamic tiling Wayland compositor that doesn't sacrifice on
its looks.")
    (properties '((upstream-name . "source")))
    (license (@ (guix licenses) bsd-3))))
(define emacs-org-tidy
  (package
    (name "emacs-org-tidy")
    (version "0.1")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/jxq0/org-tidy/archive/refs/heads/main.tar.gz")
       (sha256
        (base32 "0jm4anl64xqv43zq8hh9q14ka040az7hbwvg2qcp5ics3sdjknfx"))))
    (build-system emacs-build-system)
    (arguments '(#:tests? #f))
    (propagated-inputs (list emacs-dash))
    (home-page "https://github.com/jxq0/org-tidy")
    (synopsis "Automatically tidy Org mode property drawers")
    (description "Org-tidy is an Emacs minor mode to automatically tidy org-mode property drawers.")
    (license (@ (guix licenses) gpl3))))


(define-public emacs-book-mode
  (package
    (name "emacs-book-mode")
    (version "0.1.0")
    (source
     (origin
       (method git-fetch)
       (uri
        (git-reference
         (url "https://github.com/rougier/book-mode.git")
         (commit "master")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1bzc9v7hck6i975z1581mb3qpgzsv5i9sdvi2373ljx6c6v97h5a"))))
    (build-system emacs-build-system)
    (arguments
     '(#:tests? #f))
    (propagated-inputs
     (list emacs-nano-theme))
    (home-page "https://github.com/rougier/book-mode")
    (synopsis "Clean reading interface for Org files")
    (description
     "Book Mode is an Emacs minor mode offering a clean reading
interface for Org files. It uses large margins, styled headlines,
and a custom mode-line layout. Invoke with M-x book-mode.")
    (license (@ (guix licenses) gpl3+))))


(operating-system
  (locale "en_US.utf8")
  (timezone "Europe/Bucharest")
  (keyboard-layout (keyboard-layout "us" "dvorak"))
  (host-name "ManifoldOS")
  (bootloader (bootloader-configuration
               (bootloader grub-efi-bootloader)
               (targets (list "/boot/efi"))
               (keyboard-layout keyboard-layout)))
  (swap-devices (list (swap-space
                       (target (uuid "ba2b1983-3697-4124-8183-2d4528103325")))))
  (file-systems (cons* (file-system
                         (mount-point "/boot/efi")
                         (device (uuid "84F3-3015" 'fat32))
                         (type "vfat"))
                       (file-system
                         (mount-point "/")
                         (device (uuid "f0805da6-5c09-41e5-9a68-c4b2798909cc" 'ext4))
                         (type "ext4"))
                       %base-file-systems))
  (groups (cons* (user-group (name "seat") (system? #t))
                 %base-groups))
  (users (cons* (user-account
                 (name "aoeu")
                 (comment "Aoeu")
                 (group "users")
                 (home-directory "/home/aoeu")
                 (shell (file-append nushell "/bin/nu"))
                 (supplementary-groups '("wheel" "netdev" "audio" "video" "seat" "input")))
                %base-user-accounts))
  (sudoers-file (plain-file "sudoers"
                            "root ALL=(ALL) ALL\n%wheel ALL=(ALL) NOPASSWD: ALL\n"))
  (packages (append (list wezterm
                          starship
                          tailscale
                          github-cli
                          zoxide
                          atuin
                          zellij
                          kanata
                          nushell
                          (@ (gnu packages emacs) emacs-pgtk)
                          (@ (gnu packages emacs-xyz) emacs-auctex)
                          (@ (gnu packages emacs-xyz) emacs-avy)
                          (@ (gnu packages emacs-xyz) emacs-cape)
                          (@ (gnu packages emacs-xyz) emacs-cdlatex)
                          (@ (gnu packages emacs-xyz) emacs-vertico)
                          (@ (gnu packages emacs-xyz) emacs-orderless)
                          (@ (gnu packages emacs-xyz) emacs-marginalia)
                          (@ (gnu packages emacs-xyz) emacs-consult)
                          (@ (gnu packages emacs-xyz) emacs-embark)
                          (@ (gnu packages emacs-xyz) emacs-corfu)
                          (@ (gnu packages emacs-xyz) emacs-denote)
                          (@ (gnu packages emacs-xyz) emacs-denote-explore)
                          (@ (gnu packages emacs-xyz) emacs-dashboard)
                          (@ (gnu packages emacs-xyz) emacs-dash-docs)
                          (@ (gnu packages emacs-xyz) emacs-god-mode)
                          (@ (gnu packages emacs-xyz) emacs-magit)
                          (@ (gnu packages emacs-xyz) emacs-meow)
                          (@ (gnu packages emacs-xyz) emacs-modus-themes)
                          (@ (gnu packages emacs-xyz) emacs-nerd-icons)
                          (@ (gnu packages emacs-xyz) emacs-org-appear)
                          (@ (gnu packages emacs-xyz) emacs-org-auto-tangle)
                          (@ (gnu packages emacs-xyz) emacs-org-modern)
                          (@ (gnu packages emacs-xyz) emacs-org-modern-indent)
                          emacs-org-tidy
                          (@ (gnu packages emacs-xyz) emacs-fzf)
                          (@ (gnu packages emacs-xyz) emacs-general)
                          (@ (gnu packages emacs-xyz) emacs-svg-lib)
                          (@ (gnu packages emacs-xyz) emacs-tempel)
                          (@ (gnu packages emacs-xyz) emacs-wgrep)
                          (@ (gnu packages emacs-xyz) emacs-yasnippet)
                          emacs-org-superstar
                          emacs-org-fancy-priorities
			  emacs-leaf
			  emacs-svg-tag-mode
                          emacs-book-mode
                          git
                          television
			  jujutsu
                          fzf
                          qutebrowser
                          hyprland
                          hypridle
                          opencode)
                    %base-packages))
  (services
   (append (list (service tailscaled-service-type)
                 kanata-service
                 (simple-service 'seatd
                                 shepherd-root-service-type
                                 (list (shepherd-service
                                        (provision '(seatd))
                                        (requirement '(user-processes))
                                        (documentation "Minimal seat management daemon")
                                        (start #~(make-forkexec-constructor
                                                  (list #$(file-append seatd "/bin/seatd")
                                                        "-g" "seat")
                                                  #:log-file "/var/log/seatd.log"))
                                        (stop #~(make-kill-destructor))
                                        (respawn? #t))))
                 (service openssh-service-type
                          (openssh-configuration
                           (permit-root-login #f)
                           (password-authentication? #t))))
           (modify-services %desktop-services
             (delete gdm-service-type)
             (elogind-service-type config =>
               (elogind-configuration
                 (inherit config)
                 (handle-lid-switch 'ignore)
                 (handle-lid-switch-docked 'ignore)
                 (handle-lid-switch-external-power 'ignore)))))))
