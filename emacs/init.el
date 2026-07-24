;;; init.el --- -*- lexical-binding: t -*-
;;
;; ┌─────────────────────────────────────────────────────────────┐
;; │  BOOT ORDER                                                 │
;; │  1. straight.el bootstrap   (here)                          │
;; │  2. org from GNU ELPA       (here — must be early)          │
;; │  3. leaf + leaf-keywords    (here — needed by boot system)  │
;; │  4. manifolding-emacs       (here — loads all modules/*.org)│
;; │  5. straight.el config      (modules/straight.org)          │
;; │  6. all other modules       (modules/*.org)                 │
;; └─────────────────────────────────────────────────────────────┘

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (when (file-exists-p bootstrap-file)
    (load bootstrap-file nil 'nomessage)))

(when (file-exists-p "/etc/ssl/certs/ca-certificates.crt")
  (push "GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt" process-environment))

(straight-use-package 'org)

(straight-use-package 'leaf)
(straight-use-package 'leaf-keywords)
(eval-and-compile
  (leaf-keywords-init))

(mapc (lambda (d) (add-to-list 'load-path (expand-file-name d user-emacs-directory)))
      '("lisp/" "lisp/manifolding-emacs/"))
(require 'manifolding-emacs)

(setq manifolding-emacs--boot-warnings '())
(advice-add 'manifolding-emacs-boot :before
            (lambda () (setq manifolding-emacs--boot-warnings '())))
(advice-add 'display-warning :before
            (lambda (type message &rest _)
              (push (list :type type :message message)
                    manifolding-emacs--boot-warnings)))

(setq manifolding-emacs-package-method 'leaf
      manifolding-emacs-org-directory (expand-file-name "modules" user-emacs-directory)
      manifolding-emacs-output-directory (expand-file-name "manifolding-emacs" user-emacs-directory))
(setq inhibit-startup-screen t)
(manifolding-emacs-boot)

(global-auto-revert-mode 1)
(setq auto-revert-verbose nil
      revert-without-query '(".*")
      global-auto-revert-non-file-buffers t)

;; Everything else lives in modules/*.org.
;; See straight.org for straight.el config.
;; See keyboard.org for keybindings.
;; See buffer-management.org for buffer lifecycle.

;;; init.el ends here
