(define-module (substrate user-space root networking version-control gitpane)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (gitpane))

(define-public gitpane
  (package
    (name "gitpane")
    (version "0.8.2")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/affromero/gitpane/releases/"
                    "download/v" version
                    "/gitpane-x86_64-unknown-linux-musl.tar.gz"))
              (sha256
               (base32
                "11p0r7w7gkacq4cf415ncjxq3gmmnraazai4ip86yrsbg4hh8n69"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("gitpane" "bin/"))))
    (synopsis "Multi-repo Git workspace dashboard TUI")
    (description
     "GitPane is a multi-repo Git workspace dashboard for the terminal.
It shows branch, dirty state, ahead/behind, worktrees, changed files,
and commit history across all repositories at a glance.")
    (home-page "https://github.com/affromero/gitpane")
    (license license:expat)))
