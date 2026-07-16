(define-module (substrate user-space root shell system-monitor glances)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system pyproject)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages check)
  #:export (glances))

(define-public glances
  (package
    (name "glances")
    (version "4.3.0")
    (source
      (origin
        (method git-fetch)
        (uri (git-reference
              (url "https://github.com/nicolargo/glances")
              (commit (string-append "v" version))))
        (file-name (git-file-name name version))
        (sha256
          (base32 "1v2rsffy99ilarl5vnsz4zwb0wp3s3jnsbcbiqx53qxv88whfz71"))))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f))
    (native-inputs (list python-pytest python-setuptools))
    (propagated-inputs
      (list python-defusedxml
            python-jinja2
            python-orjson
            python-packaging
            python-psutil
            python-shtab))
    (home-page "https://github.com/nicolargo/glances")
    (synopsis "Cross-platform curses-based monitoring tool")
    (description "Glances is a curses-based monitoring tool.")
    (license license:lgpl3+)))
