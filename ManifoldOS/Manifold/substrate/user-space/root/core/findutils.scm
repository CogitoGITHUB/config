(define-module (substrate user-space root core findutils)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (findutils))

(define-public findutils
  (package
    (name "findutils")
    (version "4.10.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnu/findutils/findutils-" version ".tar.gz"))
       (sha256
        (base32 "0f0q1pyp2fw5cawbnkx16j8sn8pww06c7m28k05nh8hd7nxl7ng2"))))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags
       (list "--localstatedir=/var")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-tests
           (lambda _
             (substitute* "gl/tests/test-cjk.sh"
               (("/bin/sh") (which "sh")))
             #t)))))
    (home-page "https://www.gnu.org/software/findutils/")
    (synopsis "GNU find utilities")
    (description "GNU Find Utilities, core utilities for finding files.")
    (license license:gpl3+)))
