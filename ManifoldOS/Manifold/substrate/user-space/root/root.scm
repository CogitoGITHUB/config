(define-module (substrate user-space root root)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu services guix)
  #:use-module (gnu services ssh)
  #:use-module (gnu services networking)
  #:use-module (gnu services docker)
  #:use-module (gnu services audio)
  #:use-module (gnu services virtualization)
  #:use-module (gnu services mcron)
  #:use-module (gnu services databases)
  #:use-module (gnu services containers)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages package-management)
  #:use-module (substrate user-space root emacs-packages emacs-packages)
  #:use-module (substrate user-space root users users)
  #:use-module (substrate user-space root loaders core)
  #:use-module (substrate user-space root loaders networking)
  #:use-module (substrate user-space root loaders programming-languages)
  #:use-module (substrate user-space root loaders editors)
  #:use-module (substrate user-space root loaders emacs-packages)
  #:use-module (substrate user-space root loaders shell)
  #:use-module (substrate user-space root loaders keyboard)
  #:use-module (substrate user-space root loaders terminal)
  #:use-module (substrate user-space root loaders desktop)
  #:use-module (substrate user-space root loaders ai)
  #:use-module (substrate user-space root loaders formatters)
  #:use-module (substrate user-space root loaders lsp)
  #:use-module (substrate user-space root loaders audio)
  #:use-module (substrate user-space root loaders video)
  #:use-module (substrate user-space root loaders image)
  #:use-module (substrate user-space root loaders 3d)
  #:use-module (substrate user-space root loaders security)
  #:use-module (substrate user-space root loaders scheduling)
  #:use-module (substrate user-space root loaders compute)
  #:use-module (substrate user-space root loaders ci)
  #:use-module (substrate user-space root loaders data)
  #:use-module (substrate user-space root loaders sandbox)
  #:use-module (substrate user-space root loaders fonts)
  #:use-module (substrate user-space root loaders wayland)
  #:use-module (substrate user-space root loaders password-manager)
  #:use-module (substrate user-space root loaders games)
  #:use-module (substrate user-space root loaders containers)

  #:use-module (substrate user-space root loaders hardware)
  #:use-module (substrate user-space root loaders tex)
  #:re-export (users groups sudoers-file setuid-programs manifoldos-image seatd-service)
  #:export (root-system-packages root-system-services))

(define-public root-system-packages
  (append root-core-packages
          root-networking-packages
          root-programming-languages-packages
          root-editors-packages
          root-emacs-packages
          root-shell-packages
          root-shell-system-monitor-packages
          root-shell-power-packages
          root-shell-archive-packages
          root-shell-fetch-packages
          root-keyboard-packages
          root-terminal-packages
          root-desktop-packages
          root-ai-packages
          root-formatters-packages
          root-lsp-packages
          root-audio-packages
          root-compute-packages
          root-desktop-video-packages
          root-desktop-image-packages
          root-desktop-3d-packages
          root-desktop-wayland-packages
          root-security-packages
          root-password-manager-packages
          root-games-packages
          root-scheduling-packages
          root-ci-packages
          root-data-packages
          sandbox-packages
          font-packages
          podman-packages
            root-hardware-packages
            root-tex-packages))

(define-public root-system-services
  (append
    (list (service openssh-service-type)
          seatd-service)
    root-networking-services
    root-audio-services
    (list (service libvirt-service-type)
          (service virtlog-service-type)
          (service mcron-service-type))
    (list (service postgresql-service-type
                   (postgresql-configuration
                    (postgresql postgresql)
                    (log-directory "/var/log/postgresql"))))
    root-ci-services
    root-keyboard-services
    (list podman-service
          (service oci-service-type
                   (oci-configuration
                     (runtime 'podman)
                     (containers
                       (list (oci-container-configuration
                               (image manifoldos-image)))))))
    %base-services))
