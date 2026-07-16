;; Simplified full package declaration for git
(define-module (substrate user-space root networking version-control git)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages xml)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (substrate user-space root shell archive zlib))

(define-public git
  (package
    (name "git")
    (version "2.52.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kernel.org/software/scm/git/git-"
                           version ".tar.xz"))
       (sha256
        (base32 "1ifpkrr64g8b0vv13155gz876s2f4vcqrvhgc75lkab9dzlgxn1w"))))
    (build-system gnu-build-system)
    (arguments
     '(#:test-target "test"
       #:configure-flags
       (list "--with-gitconfig=/etc/gitconfig")))
    (native-inputs (list gettext-minimal perl))
    (inputs (list openssl expat zlib))
    (synopsis "Distributed version control system")
    (description
     "Git is a free distributed version control system designed to handle
everything from small to very large projects with speed and efficiency.")
    (license license:gpl2)
    (home-page "https://git-scm.com/")))
