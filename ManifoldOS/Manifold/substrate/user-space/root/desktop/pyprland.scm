(define-module (substrate user-space root desktop pyprland)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system pyproject)
  #:use-module (guix gexp)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (python-pyprland))

(define-public python-pyprland
  (package
    (name "python-pyprland")
    (version "3.3.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://files.pythonhosted.org/packages/source/p/pyprland/pyprland-" version ".tar.gz"))
       (sha256
        (base32 "026ciy7qsjvfzbc3x661zpam6vlb5vk31chizbkxp8lp1n9wb93a"))))
    (build-system pyproject-build-system)
    (arguments
     (list #:tests? #f
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'remove-prebuilt-binaries
                 (lambda _
                   ;; Remove pre-built native node modules that fail RUNPATH
                   (delete-file-recursively
                    "pyprland/gui/frontend/node_modules"))))))
    (propagated-inputs
     (list python-aiofiles python-aiohttp python-pillow python-typing-extensions))
    (native-inputs (list python-hatchling))
    (home-page "https://github.com/hyprland-community/pyprland")
    (synopsis "Extensions for your Hyprland desktop environment")
    (description
     "Pyprland extends the functionality of Hyprland and other Wayland
compositors, adding features like scratchpads, stash (park windows),
wallpaper management with color scheme extraction, monitor management,
and more.  It enables a high degree of customization and automation.")
    (license license:expat)))
