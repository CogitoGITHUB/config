(define-module (substrate user-space root data sqlit)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system pyproject)
  #:use-module (gnu packages docker)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages python-crypto)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages xdisorg)
  #:use-module (substrate user-space root data textual-fastdatatable)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (python-sqlit-tui))

(define-public python-sqlit-tui
  (package
    (name "python-sqlit-tui")
    (version "1.3.1.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Maxteabag/sqlit")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0l81wpzam9nqj4qmfl7yz6jll7sv417ma19rh1kyax64ia2mjvih"))))
    (build-system pyproject-build-system)
    (arguments
     '(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (delete 'sanity-check))))
    (propagated-inputs (list python-docker
                             python-keyring
                             python-pyperclip
                             python-sqlparse
                             python-textual
                             python-textual-fastdatatable))
    (native-inputs (list python-hatch-vcs python-hatchling))
    (home-page "https://github.com/Maxteabag/sqlit")
    (synopsis
     "A terminal UI for SQL Server, PostgreSQL, MySQL, SQLite, Oracle, and more")
    (description
     "This package provides a terminal UI for SQL Server, PostgreSQL,
MySQL, SQLite, Oracle, and more.")
    (license license:expat)))
