(define-module (substrate user-space root loaders tex)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (substrate user-space root tex texlive-latex-bin)
  #:use-module (substrate user-space root tex texlive-amsmath)
  #:use-module (substrate user-space root tex texlive-amsfonts)
  #:use-module (substrate user-space root tex texlive-graphics)
  #:use-module (substrate user-space root tex texlive-hyperref)
  #:use-module (substrate user-space root tex texlive-ulem)
  #:use-module (substrate user-space root tex texlive-capt-of)
  #:use-module (substrate user-space root tex texlive-wrapfig)
  #:use-module (substrate user-space root tex texlive-tools)
  #:use-module (substrate user-space root tex texlive-etoolbox)
  #:use-module (substrate user-space root tex texlive-dvipng)
  #:use-module (substrate user-space root tex texlive-preview)
  #:use-module (substrate user-space root tex texlive-xetex)
  #:use-module (substrate user-space root tex texlive-fontspec)
  #:export (root-tex-packages))

(define-public root-tex-packages
  (list texlive-latex-bin
        texlive-amsmath
        texlive-amsfonts
        texlive-graphics
        texlive-hyperref
        texlive-ulem
        texlive-capt-of
        texlive-wrapfig
        texlive-tools
        texlive-etoolbox
        texlive-dvipng
        texlive-preview
        texlive-xetex
        texlive-fontspec
        emacs-pdf-tools))
