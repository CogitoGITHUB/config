(setq package-enable-at-startup nil)
(setq user-emacs-directory (expand-file-name "~/.config/emacs/"))


(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Ensure Org is managed by straight.el, as it's a core component.
(straight-use-package 'use-package)
(straight-use-package 'org)


;;; early-init.el --- Force global Emacs root

;; Set the root directory for Emacs (works even if user-emacs-directory is undefined)
(defvar my/emacs-root (expand-file-name "~/.config/emacs/"))

;; Define user-emacs-directory if not already set
(unless (boundp 'user-emacs-directory)
  (defvar user-emacs-directory my/emacs-root))

;; Create main directory if missing
(unless (file-directory-p user-emacs-directory)
  (make-directory user-emacs-directory t))

;; Define major subpaths globally
(setq
  custom-file                (expand-file-name "custom.el" user-emacs-directory)
  package-user-dir           (expand-file-name "elpa/" user-emacs-directory)
  url-history-file           (expand-file-name "url/history" user-emacs-directory)
  recentf-save-file          (expand-file-name "recentf" user-emacs-directory)
  auto-save-list-file-prefix (expand-file-name "auto-save-list/.saves-" user-emacs-directory)
  tramp-persistency-file-name (expand-file-name "tramp" user-emacs-directory)
  bookmark-default-file      (expand-file-name "bookmarks" user-emacs-directory)
  save-place-file            (expand-file-name "places" user-emacs-directory)
  native-comp-eln-load-path  (list (expand-file-name "eln-cache/" user-emacs-directory))
)
