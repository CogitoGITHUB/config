(define-module (substrate user-space root password-manager password-store)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages aidc)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages suckless)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg)
  #:export (password-store))

(define-public password-store
  (package
    (name "password-store")
    (version "1.7.4")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "git://git.zx2c4.com/password-store")
             (commit version)))
       (sha256
        (base32 "17zp9pnb3i9sd2zn9qanngmsywrb7y495ngcqs6313pv3gb83v53"))
       (file-name (git-file-name name version))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:make-flags
      #~(list (string-append "PREFIX=" #$output)
              "WITH_ALLCOMP=yes"
              (string-append "BASHCOMPDIR="
                             #$output "/share/bash-completion/completions"))
      #:parallel-tests? #f
      #:test-target "test"
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'build))))
    (inputs
     (list bash-minimal
           coreutils
           dmenu
           git
           gnupg
           qrencode
           sed
           tree
           util-linux
           which
           wl-clipboard
           xclip
           xdotool))
    (home-page "https://www.passwordstore.org/")
    (synopsis "Encrypted password manager")
    (description "Password-store is a password manager which uses GnuPG to
store and retrieve passwords.")
    (license license:gpl2+)))
