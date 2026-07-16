(define-module (substrate user-space root desktop hyprvim)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (hyprvim))

(define-public hyprvim
  (package
    (name "hyprvim")
    (version "2.0.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/uhs-robert/hyprvim/archive/refs/tags/v"
                                  version ".tar.gz"))
              (sha256
               (base32 "1aim7ipv9hqmjbaf9v4ibxr6w7qhbnf99y54gwn2cid4nr9bizf3"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan #~'(("." "share/hyprvim/"))))
    (home-page "https://github.com/uhs-robert/hyprvim")
    (synopsis "Vim keybind system for Hyprland with a Which-Key HUD")
    (description
     "HyprVim brings the power of Vim keybindings and motions to your Hyprland
desktop environment.  Built on Hyprland's native submap system, it uses standard
GUI application keyboard shortcut macros to emulate Vim-style navigation and
text editing.")
    (license license:expat)))
