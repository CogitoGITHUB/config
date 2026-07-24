(define-module (substrate user-space root emacs-packages emacs-packages)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (gnu packages emacs-build)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system emacs)
  #:use-module (guix gexp)
  #:use-module (guix licenses)
  #:export (emacs-packages))

;;; ============================================================================
;;; Custom Emacs Packages
;;; ============================================================================

(define-public emacs-modaled
  (package
    (name "emacs-modaled")
    (version "0.9.2")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/DCsunset/modaled")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1g73nmgcv0vwx40i0ymcj5l4fbw36k1z3w9wsnfhm72fwbx2h2na"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/DCsunset/modaled")
    (synopsis "Build your own minor modes for modal editing in Emacs")
    (description "Modaled is a fully customizable modal editing framework for Emacs.")
    (license agpl3+)))

(define-public emacs-super-save-0.5
  (package
    (inherit emacs-super-save)
    (version "0.5.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/bbatsov/super-save/archive/refs/tags/v"
             version ".tar.gz"))
       (sha256
        (base32
         "0ma5qfm8l6bnqbcsmrfzw95drmhiv6a6l1kjp2b8b48clgazxb0y"))))))

(define-public emacs-centered-cursor-mode
  (package
    (name "emacs-centered-cursor-mode")
    (version "0.5.13")
    (source
     (origin
       (method url-fetch)
       (uri "https://raw.githubusercontent.com/andre-r/centered-cursor-mode.el/master/centered-cursor-mode.el")
       (sha256
        (base32 "1f2g2ln4zknak707yaayvs77j5fasrz247vsvfljy4q3zqnd4rwh"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/andre-r/centered-cursor-mode.el")
    (synopsis "Keep cursor vertically centered in Emacs")
    (description "Minor mode that keeps the cursor vertically centered in the window.")
    (license gpl2+)))

(define-public emacs-centaur-tabs-latest
  (package
    (inherit emacs-centaur-tabs)
    (version "0.0.0-5ec350d")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/ema2159/centaur-tabs/archive/"
             "5ec350da6cacc34ac0efaac17d6ac5031ef82bd4.tar.gz"))
       (sha256
        (base32
         "1hjl4zcs3rrjbvmxyis90dl5di3c84nxn2yrilb2acb9rgn7ma1d"))))
    (arguments
     (list #:tests? #f))
    (propagated-inputs
     (list emacs-powerline emacs-nerd-icons))))

(define-public emacs-org-tidy
  (package
    (name "emacs-org-tidy")
    (version "0.1")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/jxq0/org-tidy/archive/refs/heads/main.tar.gz")
       (sha256
        (base32 "0jm4anl64xqv43zq8hh9q14ka040az7hbwvg2qcp5ics3sdjknfx"))))
    (build-system emacs-build-system)
    (arguments '(#:tests? #f))
    (propagated-inputs (list emacs-dash))
    (home-page "https://github.com/jxq0/org-tidy")
    (synopsis "Automatically tidy Org mode property drawers")
    (description "Org-tidy is an Emacs minor mode to automatically tidy org-mode property drawers.")
    (license gpl3)))

(define-public emacs-consult-todo
  (let ((commit "f9ba063a6714cb95ddbd886786ada93771f3c140")
        (revision "0"))
    (package
      (name "emacs-consult-todo")
      (version (git-version "0.5.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/liuyinz/consult-todo")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "13lfm1kg3llda0w4mwbaai6vrsaymq3yn4kagpvkh9i0iy22a5ii"))))
      (build-system emacs-build-system)
      (propagated-inputs
       (list emacs-consult emacs-hl-todo))
      (home-page "https://github.com/liuyinz/consult-todo")
      (synopsis "Search and jump to hl-todo keywords with consult")
      (description "Provides consult-based commands to search and jump to TODO keywords.")
      (license gpl3+))))

;;; ============================================================================
;;; Emacs Packages List
;;; ============================================================================

(define-public emacs-packages
  (list
   ;; Custom packages
   emacs-modaled
   emacs-super-save-0.5
   emacs-centered-cursor-mode
   emacs-centaur-tabs-latest
   emacs-org-tidy
   emacs-consult-todo
   ;; Core emacs
   emacs-pgtk
   ;; Completion
   emacs-vertico
   emacs-orderless
   emacs-marginalia
   emacs-consult
   emacs-embark
   emacs-corfu
   emacs-cape
   ;; Org
   emacs-org-tree-slide
   emacs-org-appear
   emacs-org-auto-tangle
   emacs-org-modern
   emacs-org-modern-indent
   emacs-org-superstar
   emacs-org-sticky-header
   emacs-org-rainbow-tags
   emacs-org-ql
   emacs-org-fancy-priorities
   emacs-org-cliplink
   emacs-org-generate
   emacs-org-books
   emacs-org-chef
   emacs-org-now
   emacs-org-contacts
   emacs-org-drill
   emacs-org-drill-table
   emacs-org-mem
   emacs-org-street
   emacs-interleave
   emacs-citar
   emacs-denote
   emacs-denote-explore
    emacs-vulpea
    emacs-vulpea-ui
   emacs-doct
   emacs-gnosis
   emacs-deft
   emacs-consult-org-roam
   emacs-consult-notes
   ;; UI
   emacs-dashboard
   emacs-doom-modeline
   emacs-nano-modeline
   emacs-modus-themes
   emacs-nerd-icons
   emacs-dirvish
   emacs-treemacs
   emacs-treemacs-extra
   emacs-treemacs-nerd-icons
   emacs-olivetti
   emacs-hide-mode-line
   emacs-minions
   emacs-golden-ratio
   emacs-svg-lib
   emacs-svg-tag-mode
   emacs-goggles
   emacs-hl-todo
   emacs-ace-window
   emacs-activities
   ;; Edit
   emacs-avy
   emacs-general
   emacs-god-mode
   emacs-hydra
   emacs-pretty-hydra
   emacs-dash
   emacs-s
   emacs-tempel
   emacs-yasnippet
   emacs-wgrep
   emacs-multiple-cursors
   emacs-multifiles
   emacs-vundo
   emacs-loccur
   emacs-comment-tags
   emacs-bookmark-plus
   emacs-projectile
   emacs-perspective
   emacs-persp-mode
   emacs-literate-elisp
   emacs-spray
   emacs-speed-type
   emacs-caps-lock
   emacs-auto-sudoedit
   emacs-modaled
   emacs-polymode-org
   emacs-mmm-mode
   emacs-miniedit
   emacs-toodoo
   ;; Git
   emacs-magit
   emacs-magit-todos
   emacs-git-timemachine
   emacs-git-gutter
   emacs-git-messenger
   emacs-git-link
   ;; Language/writing
   emacs-auctex
   emacs-cdlatex
   emacs-kana
   emacs-kanji
   emacs-password-generator
   ;; Terminal/shell
   emacs-vterm
   emacs-vterm-toggle
   emacs-multi-vterm
   ;; Notes/knowledge
   emacs-hyperbole
   emacs-dash-docs
   emacs-consult-yasnippet
   emacs-denote-explore
   ;; Web/feeds
   emacs-elfeed
   emacs-elfeed-org
   emacs-elfeed-goodies
   emacs-eww-lnum
   emacs-hackernews
   emacs-youtube-dl
   emacs-enwc
   ;; Misc
   emacs-everywhere
   emacs-emojify
   emacs-geoclue
   emacs-popup
   emacs-popup-kill-ring
   emacs-neotree
   emacs-ivy-omni-org
   emacs-esup
   emacs-restart-emacs
   emacs-benchmark-init
   emacs-leaf
   emacs-macrostep
   emacs-eros
   emacs-bug-hunter
   emacs-elisp-refs
   emacs-simple-httpd
   emacs-websocket
   emacs-helpful
   emacs-xhair
   emacs-fzf))
