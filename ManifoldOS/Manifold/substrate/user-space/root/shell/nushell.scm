(define-module (substrate user-space root shell nushell)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (nushell))

(define-public nushell
  (package
    (name "nushell")
    (version "0.114.0")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "https://github.com/nushell/nushell/releases/download/"
                            version "/nu-" version "-x86_64-unknown-linux-gnu.tar.gz"))
        (sha256
          (base32 "1292qy7f09609wji7ivkxcwb6q43paayk99n2zagcy1npxz7g5iq"))))
    (build-system trivial-build-system)
    (inputs (list patchelf glibc `(,gcc "lib") zlib tar gzip))
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
                 (zlib (assoc-ref %build-inputs "zlib"))
                 (interp (string-append glibc "/lib/ld-linux-x86-64.so.2"))
                 (rpath (string-append gcc-lib "/lib" ":" zlib "/lib"))
                 (workdir (string-append (getenv "TMPDIR") "/extract")))
            (setenv "PATH" (string-append (dirname tar) ":" (dirname gzip)))
            (mkdir-p workdir)
            (mkdir-p (string-append out "/bin"))
            (with-directory-excursion workdir
              (invoke "tar" "xzf" src))
            (copy-file (string-append workdir "/nu-0.114.0-x86_64-unknown-linux-gnu/nu")
                       (string-append out "/bin/nu"))
            (chmod (string-append out "/bin/nu") #o755)
            (invoke patchelf "--set-interpreter" interp
                    "--set-rpath" rpath
                    (string-append out "/bin/nu")))))))
    (home-page "https://www.nushell.sh")
    (synopsis "Shell with a structured approach to the command line")
    (description
     "Nu draws inspiration from projects like PowerShell, functional
programming languages, and modern CLI tools.  Rather than thinking of files
and services as raw streams of text, Nu looks at each input as something with
structure.  For example, when you list the contents of a directory, what you
get back is a table of rows, where each row represents an item in that
directory.  These values can be piped through a series of steps, in a series
of commands called a ``pipeline''.")
    (license license:expat)))