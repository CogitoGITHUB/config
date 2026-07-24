;;; early-init.el --- -*- lexical-binding: t -*-

(setq make-backup-files nil)
(setq-default truncate-lines nil)
(setq-default word-wrap t)
(add-hook 'after-init-hook #'global-visual-line-mode)

(setopt use-short-answers t)
(unless noninteractive
  (menu-bar-mode -1)
  (when (fboundp 'tool-bar-mode)   (tool-bar-mode -1))
  (when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1)))

(add-to-list 'warning-suppress-types '(org-version-mismatch))

(let ((site-lisp (expand-file-name "~/.guix-profile/share/emacs/site-lisp/")))
  (when (file-directory-p site-lisp)
    (let ((dirs (directory-files site-lisp t "^[^.]")))
      (dolist (dir (reverse dirs))
        (when (file-directory-p dir)
          (push dir load-path))))))

(let ((site-lisp "/run/current-system/profile/share/emacs/site-lisp/"))
  (when (file-directory-p site-lisp)
    (let ((dirs (directory-files site-lisp t "^[^.]")))
      (dolist (dir (reverse dirs))
        (when (file-directory-p dir)
          (push dir load-path))))))

;;; early-init.el ends here
