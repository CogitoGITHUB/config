(define-module (substrate user-space root loaders tex)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (substrate user-space root formatters texlive-latex-bin)
  #:use-module (substrate user-space root formatters texlive-amsmath)
  #:use-module (substrate user-space root formatters texlive-amsfonts)
  #:use-module (substrate user-space root formatters texlive-graphics)
  #:use-module (substrate user-space root formatters texlive-hyperref)
  #:use-module (substrate user-space root formatters texlive-ulem)
  #:use-module (substrate user-space root formatters texlive-capt-of)
  #:use-module (substrate user-space root formatters texlive-wrapfig)
  #:use-module (substrate user-space root formatters texlive-tools)
  #:use-module (substrate user-space root formatters texlive-etoolbox)
  #:use-module (substrate user-space root formatters texlive-dvipng)
  #:use-module (substrate user-space root formatters texlive-preview)
  #:use-module (substrate user-space root formatters texlive-xetex)
  #:use-module (substrate user-space root formatters texlive-fontspec)
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
