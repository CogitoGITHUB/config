(define-module (substrate user-space root desktop wayland appcards)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (gnu packages bash)
  #:use-module (substrate user-space root desktop quickshell)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (appcards))

(define-public appcards
  (package
    (name "appcards")
    (version "0.0.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/CogitoGITHUB/AppCards")
             (commit "51167aa4e171d8cb130427bc885ffaf08f2682e2")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "02iav6szs0pmbkbdw2vfrrqyikjxq2j629ncx4348jxcagk4kg0c"))))
    (build-system trivial-build-system)
    (inputs (list bash-minimal quickshell))
    (arguments
     (list #:modules (quote ((guix build utils)))
           #:builder
       (quasiquote (begin
         (use-modules (guix build utils))
         (let* ((out (assoc-ref %outputs "out"))
                (src (assoc-ref %build-inputs "source"))
                (bash (string-append (assoc-ref %build-inputs "bash-minimal") "/bin/bash"))
                (qs (string-append (assoc-ref %build-inputs "quickshell") "/bin/qs"))
                (config-dir (string-append out "/share/appcards/tui"))
                (bin-dir (string-append out "/bin"))
                (script (string-append bin-dir "/omarchy-tui-shell")))
           (mkdir-p config-dir)
           (copy-recursively (string-append src "/tui") config-dir)
           (mkdir-p bin-dir)
           (copy-file (string-append src "/bin/omarchy-tui-shell") script)
           (chmod script #o755)
           (substitute* script
             (("#!.*") (string-append "#!" bash)))
           (substitute* script
             (("qs ") (string-append qs " ")))
           (substitute* script
             (("CONFIG_NAME=\"tui\"")
              (string-append
                "CONFIG_NAME=\"tui\"\n"
                "APPCARDS_CONFIG_DIR=\"" config-dir "\"\n"
                "USER_CONFIG_DIR=\"$HOME/.config/quickshell/$CONFIG_NAME\"\n"
                "# Ensure the config symlink exists\n"
                "if [ ! -L \"$USER_CONFIG_DIR\" ] || [ \"$(readlink \"$USER_CONFIG_DIR\")\" != \"$APPCARDS_CONFIG_DIR\" ]; then\n"
                "  mkdir -p \"$HOME/.config/quickshell\"\n"
                "  ln -sfn \"$APPCARDS_CONFIG_DIR\" \"$USER_CONFIG_DIR\"\n"
                "fi\n")))
           (substitute* script
             (("CONFIG_PATH=.*")
              "CONFIG_PATH=\"$USER_CONFIG_DIR/shell.qml\""))
           #t)))))
    (home-page "https://github.com/CogitoGITHUB/AppCards")
    (synopsis "Quickshell application launcher with playing-card fan UI")
    (description
     "AppCards is a Quickshell-based application launcher that displays
installed desktop applications as a hand of playing cards fanned out
at the bottom of the screen.  It features 3D card flips, parallax
mouse tracking, and search-as-you-type filtering.")
    (license license:expat)))
