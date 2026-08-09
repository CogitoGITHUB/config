(define-module (substrate user-space root terminal ghostty)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix packages)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages base)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages commencement)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (ghostty))

(define-public ghostty
  (package
    (name "ghostty")
    (version "1.3.1")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/mkasberg/ghostty-ubuntu/releases/download/"
              version "-0-ppa2/ghostty_" version "-0.ppa2_amd64_24.04.deb"))
        (sha256 (base32 "0iydp2a1m43ij3i6pi2jyicm6w81i5npvz4f84k48m7gac0l93a7"))))
    (build-system trivial-build-system)
    (arguments
      '(#:modules ((guix build utils))
        #:builder
        (begin
          (use-modules (guix build utils))
          (let* ((out  (assoc-ref %outputs "out"))
                 (src  (assoc-ref %build-inputs "source"))
                 (ar   (string-append (assoc-ref %build-inputs "binutils")
                                      "/bin/ar"))
                 (tar  (string-append (assoc-ref %build-inputs "tar")
                                      "/bin/tar"))
                 (zstd (string-append (assoc-ref %build-inputs "zstd")
                                      "/bin/zstd"))
                 (work "/tmp/deb-work"))
            (mkdir-p work)
            (with-directory-excursion work
              (invoke ar "x" src))
            (mkdir-p "/tmp/deb-data")
            (with-directory-excursion "/tmp/deb-data"
              (invoke tar (string-append "--use-compress-program=" zstd) "-xf"
                      (string-append work "/data.tar.zst")))
            (mkdir-p (string-append out "/bin"))
            (copy-file "/tmp/deb-data/usr/bin/ghostty"
                       (string-append out "/bin/.ghostty-real"))
            (chmod (string-append out "/bin/.ghostty-real") #o555)
            (when (file-exists? "/tmp/deb-data/usr/share")
              (copy-recursively "/tmp/deb-data/usr/share"
                                (string-append out "/share")))
            ;; Wrapper: the prebuilt binary dynamically links system libs
            ;; (gtk4, libadwaita, ...) which are only `inputs' here. Export
            ;; LD_LIBRARY_PATH from every input's lib dir at runtime.
            (let* ((lib-dirs
                    (filter (lambda (d) (and d (directory-exists? d)))
                            (map (lambda (entry)
                                   (string-append (cdr entry) "/lib"))
                                 %build-inputs)))
                   (loader (string-append (assoc-ref %build-inputs "glibc")
                                          "/lib/ld-linux-x86-64.so.2"))
                   (wrapper (string-append out "/bin/ghostty")))
              (call-with-output-file wrapper
                (lambda (port)
                  (format port "#!/bin/sh\nexport LD_LIBRARY_PATH=~a\nexec \"~a\" \"${0%/*}/.ghostty-real\" \"$@\"\n"
                          (string-join lib-dirs ":") loader)))
              (chmod wrapper #o555))
            #t))))
    (inputs
     (list glibc
           gtk ; ManifoldOS Guix: gtk is GTK4 (4.22.1)
           libadwaita
           gtk4-layer-shell
           glib
           libx11
           fontconfig
           freetype
           harfbuzz
           oniguruma
           wayland))
    (native-inputs
     (list binutils tar zstd))
    (home-page "https://ghostty.org")
    (synopsis "Fast, feature-rich, cross-platform terminal emulator")
    (description "Ghostty is a terminal emulator that differentiates itself
by being fast, feature-rich, and native. This package installs the
prebuilt binary from the ghostty-ubuntu community .deb (Ghostty does not
ship official Linux binaries).")
    (license license:expat)))

ghostty