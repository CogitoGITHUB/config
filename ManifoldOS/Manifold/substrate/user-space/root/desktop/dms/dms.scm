(define-module (substrate user-space root desktop dms dms)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages qt)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (dms))

(define-public dms
  (package
    (name "dms")
    (version "1.5.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/AvengeMedia/DankMaterialShell/releases/download/v" version "/dms-full-amd64.tar.gz"))
              (sha256 (base32 "05s73jql62gw1vxaw8p3h1q5zv6dv06z13ijwd22zwxz1mci4wgv"))))
    (build-system trivial-build-system)
    (arguments
     (list #:modules '((guix build utils))
           #:builder
           #~(begin
               (use-modules (guix build utils))
               (let* ((out (assoc-ref %outputs "out"))
                      (src (assoc-ref %build-inputs "source"))
                      (qtwayland (assoc-ref %build-inputs "qtwayland"))
                      (tar (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                      (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin"))
                      (qt-plugin-path (string-append qtwayland "/lib/qt6/plugins")))
                 (setenv "PATH" gzip)
                 (invoke tar "-xzf" src)

                 (mkdir-p (string-append out "/libexec"))
                 (copy-file "bin/dms" (string-append out "/libexec/dms"))
                 (chmod (string-append out "/libexec/dms") #o555)

                 (mkdir-p (string-append out "/bin"))
                 (call-with-output-file (string-append out "/bin/dms")
                   (lambda (port)
                     (format port "#!/bin/sh
QT_QPA_PLATFORM=wayland QT_PLUGIN_PATH=\"$QT_PLUGIN_PATH:~a\" exec ~a/libexec/dms \"$@\"\n"
                             qt-plugin-path out)))
                 (chmod (string-append out "/bin/dms") #o555)

                 (mkdir-p (string-append out "/share/bash-completion/completions"))
                 (copy-file "completions/completion.bash"
                            (string-append out "/share/bash-completion/completions/dms"))
                 (mkdir-p (string-append out "/share/zsh/site-functions"))
                 (copy-file "completions/completion.zsh"
                            (string-append out "/share/zsh/site-functions/_dms"))
                 (mkdir-p (string-append out "/share/fish/vendor_completions.d"))
                 (copy-file "completions/completion.fish"
                            (string-append out "/share/fish/vendor_completions.d/dms.fish"))
                 (copy-recursively "dms" (string-append out "/share/dms"))
                 (copy-recursively "docs" (string-append out "/share/doc/dms"))
                 (install-file "INSTALL.md" (string-append out "/share/doc/dms"))))))
    (inputs (list tar gzip qtwayland))
    (home-page "https://danklinux.com")
    (synopsis "Desktop shell for Wayland compositors")
    (description "DankMaterialShell is a complete desktop shell for Wayland compositors. It replaces waybar, swaylock, swayidle, mako, fuzzel, polkit, and more. Built with Quickshell and Go.")
    (license license:expat)))
