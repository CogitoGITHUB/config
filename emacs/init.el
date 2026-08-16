;;; init.el --- -*- lexical-binding: t -*-
;;
;; ┌─────────────────────────────────────────────────────────────┐
;; │  BOOT ORDER                                                 │
;; │  1. straight.el bootstrap                                   │
;; │  2. straight/build/* → load-path                            │
;; │  3. org from GNU ELPA                                       │
;; │  4. leaf + leaf-keywords                                    │
;; │  5. manifolding-emacs                                       │
;; │  6. modules/*.org                                           │
;; └─────────────────────────────────────────────────────────────┘


;;; Straight.el Bootstrap

(defvar bootstrap-version)

(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        user-emacs-directory))
      (bootstrap-version 6))
  (when (file-exists-p bootstrap-file)
    (load bootstrap-file nil 'nomessage)))


;;; Straight Build Load Paths

;; straight.el builds each package in:
;;
;;   ~/.config/emacs/straight/build/<package>/
;;
;; Add every package build directory to `load-path` so that:
;;
;;   (require 'modaled)
;;   (require 'pretty-hydra)
;;   (require 'git-gutter)
;;
;; and similar package loads can resolve normally.

(let ((straight-build-dir
       (expand-file-name "straight/build/" user-emacs-directory)))
  (when (file-directory-p straight-build-dir)
    (dolist (dir (directory-files straight-build-dir t "^[^.]" t))
      (when (file-directory-p dir)
        (add-to-list 'load-path dir)))))


;;; Git SSL CA Certificate

(when (file-exists-p "/etc/ssl/certs/ca-certificates.crt")
  (push "GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt"
        process-environment))


;;; Core Packages

(straight-use-package 'org)

(straight-use-package 'leaf)
(straight-use-package 'leaf-keywords)

(eval-and-compile
  (leaf-keywords-init))


;;; Manifolding-Emacs

(mapc
 (lambda (d)
   (add-to-list
    'load-path
    (expand-file-name d user-emacs-directory)))
 '("lisp/"
   "lisp/manifolding-emacs/"))

(require 'manifolding-emacs)


;;; Boot Diagnostics

(setq manifolding-emacs--boot-warnings '())

(advice-add
 'manifolding-emacs-boot
 :before
 (lambda ()
   (setq manifolding-emacs--boot-warnings '())))

(advice-add
 'display-warning
 :before
 (lambda (type message &rest _)
   (push
    (list :type type
          :message message)
    manifolding-emacs--boot-warnings)))


;;; Manifolding-Emacs Configuration

(setq
 manifolding-emacs-package-method 'leaf
 manifolding-emacs-org-directory
 (expand-file-name "modules" user-emacs-directory)
 manifolding-emacs-output-directory
 (expand-file-name "manifolding-emacs" user-emacs-directory))


;;; Startup

(setq inhibit-startup-screen t)

(manifolding-emacs-boot)


;;; Auto Revert

(global-auto-revert-mode 1)

(setq
 auto-revert-verbose nil
 revert-without-query '(".*")
 global-auto-revert-non-file-buffers t)


;;; End

;; Everything else lives in modules/*.org.
;;
;; See:
;;   modules/straight.org
;;   modules/keyboard.org
;;   modules/buffer-management.org

;;; init.el ends here
