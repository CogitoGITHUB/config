(define-module (substrate user-space root desktop video kino)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system go)
  #:use-module (guix gexp)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages golang-xyz)
  #:use-module (gnu packages golang-build)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (go-github-com-mmcdole-kino))

(define-public go-github-com-mmcdole-kino
  (package
    (name "go-github-com-mmcdole-kino")
    (version "0.4.1")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/mmcdole/kino")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32 "0lz4yc14r36vxrcjv3ggihj78zdphy5cm3sijsswscmfxw23v72c"))
              (modules '((guix build utils)))
              (snippet
               #~(begin
                   (substitute* "go.mod"
                     (("go 1.25.5") "go 1.24"))))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/mmcdole/kino"
      #:install-source? #f
      #:phases
      #~(modify-phases %standard-phases
          (replace 'build
            (lambda* (#:key import-path #:allow-other-keys)
              (invoke "go" "install" "-ldflags=-s -w" "-trimpath"
                      (string-append import-path "/cmd/kino")))))))
    (propagated-inputs (list go-github-com-charmbracelet-bubbles
                             go-github-com-charmbracelet-bubbletea
                             go-github-com-charmbracelet-lipgloss
                             go-github-com-sahilm-fuzzy
                             go-github-com-spf13-viper
                             go-go-etcd-io-bbolt
                             go-golang-org-x-term))
    (synopsis "Terminal client for browsing and playing Plex or Jellyfin media")
    (description "Kino is a fast terminal client for browsing and playing media from Plex and Jellyfin servers. Features fuzzy search, Vim-style navigation, playlist management, watch status tracking, and an inspector panel for detailed metadata.")
    (home-page "https://github.com/mmcdole/kino")
    (license license:expat)))

go-github-com-mmcdole-kino
