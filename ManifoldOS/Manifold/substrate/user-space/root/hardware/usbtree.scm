(define-module (substrate user-space root hardware usbtree)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (usbtree))

(define-public usbtree
  (package
    (name "usbtree")
    (version "0.0.1")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "https://github.com/gnomeria/usbtree/releases/download/v"
                            version "/usbtree_" version "_linux-amd64.tar.gz"))
        (sha256 (base32 "0cyb4a95inxnl8kwv7fcj1p09vpl519jr13n1r83gzilfmj1spgn"))))
    (build-system trivial-build-system)
    (inputs (list patchelf glibc `(,gcc "lib") tar gzip))
    (arguments
      (list #:modules (quote ((guix build utils)))
            #:builder
        (quasiquote (begin
          (use-modules (guix build utils))
          (let* ((out (assoc-ref %outputs "out"))
                 (src (assoc-ref %build-inputs "source"))
                 (tar (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                 (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin/gzip"))
                 (patchelf (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
                 (glibc (assoc-ref %build-inputs "glibc"))
                 (gcc-lib (assoc-ref %build-inputs "gcc"))
                 (interp (string-append glibc "/lib/ld-linux-x86-64.so.2"))
                 (rpath (string-append gcc-lib "/lib"))
                 (workdir (string-append (getenv "TMPDIR") "/extract")))
            (setenv "PATH" (string-append (dirname tar) ":" (dirname gzip)))
            (mkdir-p workdir)
            (mkdir-p (string-append out "/bin"))
            (with-directory-excursion workdir
              (invoke "tar" "xzf" src))
            (copy-file (string-append workdir "/usbtree")
                       (string-append out "/bin/usbtree"))
            (chmod (string-append out "/bin/usbtree") #o755)
            (invoke patchelf "--set-interpreter" interp
                    "--set-rpath" rpath
                    (string-append out "/bin/usbtree")))))))
    (home-page "https://github.com/gnomeria/usbtree")
    (synopsis "Cross-platform TUI for inspecting the USB device tree")
    (description
     "Usbtree is a terminal UI for inspecting the USB device tree on Linux,
macOS, and Windows.  It enumerates devices via nusb (pure Rust, no root, no
libusb) and displays them in a ratatui-based interface.")
    (license license:expat)))
