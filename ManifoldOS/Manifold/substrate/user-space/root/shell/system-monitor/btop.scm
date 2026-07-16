(define-module (substrate user-space root shell system-monitor btop)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages markup)
  #:use-module (gnu packages gcc)
  #:export (btop))

(define-public btop
  (package
    (name "btop")
    (version "1.4.6")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/aristocratos/btop")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1nj58dbv3c0rj8fngldkyrmdmacmjnbg8ch1c07ik97kqnnzd3l7"))))
    (build-system gnu-build-system)
    (native-inputs (list lowdown gcc))
    (arguments
     '(#:tests? #f
       #:make-flags
       (list (string-append "PREFIX=" (assoc-ref %outputs "out"))
             (string-append "CC=" (assoc-ref %build-inputs "gcc") "/bin/gcc"))
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))))
    (home-page "https://github.com/aristocratos/btop")
    (synopsis "Resource monitor")
    (description "Btop++ provides unified monitoring of CPU, memory, network and processes.")
    (license license:asl2.0)))
