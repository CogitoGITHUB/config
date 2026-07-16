(define-module (substrate user-space root loaders core)
  #:use-module (substrate user-space root core sudo)
  #:use-module (substrate user-space root core inetutils)
  #:use-module (gnu packages base)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages file)
  #:use-module (substrate user-space root shell archive unzip)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages monitoring)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages man)
  
  #:re-export (sudo gzip)
  #:export (root-core-packages))

(define-public root-core-packages
  (list coreutils
        findutils
        grep
        inetutils
        kmod
        sudo
        util-linux
        patchelf
        file
        wget
        gzip
        tar
        unzip
        ripgrep
        fd
        bat
        man-db
        procps
        jujutsu
        fswatch))