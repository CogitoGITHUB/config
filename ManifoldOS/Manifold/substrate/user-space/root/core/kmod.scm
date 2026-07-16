(define-module (substrate user-space root core kmod)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:export (kmod))

(define-public kmod
  (package
    (name "kmod")
    (version "29")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kernel.org/linux/utils/kernel/kmod/kmod-" version ".tar.xz"))
       (sha256
        (base32 "0am54mi5rk72g5q7k6l6f36gw3r9vwgjmyna43ywcjhqmakyx00b"))))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags (list "--with-xz" "--with-zlib" "--with-zstd"
                               "--disable-test-modules")
       #:tests? #f))
    (inputs (list xz zlib zstd))
    (home-page "https://git.kernel.org/pub/scm/utils/kernel/kmod/kmod.git/")
    (synopsis "Kernel module management utilities")
    (description "Kmod is a set of tools to handle common tasks with Linux kernel modules.")
    (license license:gpl2+)))
