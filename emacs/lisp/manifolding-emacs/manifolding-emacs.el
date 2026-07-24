;;; manifolding-emacs.el --- Managed Emacs configuration through org files -*- lexical-binding: t; -*-

;;; Commentary:

;; Public entry point.  Requires every manifolding-emacs-*.el module and
;; exposes the commands you call day to day: `manifolding-emacs-boot',
;; `manifolding-emacs-reload', `manifolding-emacs-reload-current-buffer',
;; `manifolding-emacs-preview', `manifolding-emacs-preview-mode'.
;; Doctor/lockfile/error commands are autoloaded from their own files
;; via this require chain too, so `M-x manifolding-emacs-doctor' etc.
;; just work.

;;; Code:

(require 'manifolding-emacs-vars)
(require 'manifolding-emacs-errors)
(require 'manifolding-emacs-org-parse)
(require 'manifolding-emacs-package-builder)
(require 'manifolding-emacs-remote)
(require 'manifolding-emacs-compiler)
(require 'manifolding-emacs-lockfile)
(require 'manifolding-emacs-splash)
(require 'manifolding-emacs-doctor)

(defun manifolding-emacs-reload ()
  "Recompile every Org file, quietly (no splash)."
  (interactive)
  (manifolding-emacs-compile-directory))

(defun manifolding-emacs-reload-current-buffer ()
  "Compile (downloading first if needed) the current Org file."
  (interactive)
  (let ((remote-file-plist (manifolding-emacs-file-remote (buffer-file-name (current-buffer)))))
    (when remote-file-plist
      (manifolding-emacs-pull-remote-file remote-file-plist)
      (let ((manifolding-emacs-compiling-remote t))
        (manifolding-emacs-compile-file (manifolding-emacs-remote-plist-to-org-file remote-file-plist)))))
  (manifolding-emacs-compile-file (buffer-file-name (current-buffer))))

(defun manifolding-emacs-preview ()
  "Show what the current buffer would expand to, without evaluating it."
  (interactive)
  (let* ((buffer (get-buffer-create "*manifolding-emacs preview*"))
         (_ (display-buffer buffer))
         (manifolding-emacs-wrap-statements-in-condition nil)
         (file (buffer-file-name (current-buffer)))
         (manifolding-emacs-packages nil)
         (loose-forms (manifolding-emacs-concatenate-source-blocks file))
         (output (concat (mapconcat #'identity loose-forms "\n") "\n"
                          (manifolding-emacs-build-packages file))))
    (with-current-buffer buffer
      (emacs-lisp-mode) (read-only-mode 1)
      (let ((inhibit-read-only t)) (erase-buffer) (insert output) (goto-char (point-min))))))

(define-minor-mode manifolding-emacs-preview-mode
  "Keep the *manifolding-emacs preview* buffer in sync on save."
  :lighter " manifolding-emacs-preview"
  (if manifolding-emacs-preview-mode
      (add-hook 'after-save-hook #'manifolding-emacs-preview nil t)
    (remove-hook 'after-save-hook #'manifolding-emacs-preview t)))

(defun manifolding-emacs--splash-progress (buf)
  (lambda (current total file) (manifolding-emacs-splash-update-progress buf current total file)))

(defun manifolding-emacs-boot ()
  "Compile every Org file, with a splash screen, structured error
tracking, an idle sweep to surface deferred-load errors early, and
(optionally) an automatic version freeze if the boot was clean."
  (interactive)
  (let ((manifolding-emacs--booting t) (fatal nil))
    (manifolding-emacs-errors-clear-boot-state)
    (when manifolding-emacs-mode-line-indicator (manifolding-emacs-doctor-indicator-mode 1))
    (condition-case err
        (manifolding-emacs-with-warning-capture
         (let ((buf (manifolding-emacs-show-splash)) (manifolding-emacs--boot-phase :compiling))
           (manifolding-emacs-compile-directory (manifolding-emacs--splash-progress buf))))
      (error (setq fatal err)))
    (manifolding-emacs-errors-save-log)
    (unless fatal
      (manifolding-emacs-maybe-freeze-on-clean-boot)
      (manifolding-emacs-doctor-schedule-idle-sweep))
    (message "manifolding-emacs: %s%d error(s), %d warning(s)" (if fatal "BOOT THREW - " "")
             (length (manifolding-emacs-errors-list)) (length (manifolding-emacs-warnings-list)))
    (let ((buf (get-buffer "*Manifolding-Emacs*")))
      (when (buffer-live-p buf)
        (with-current-buffer buf
          (let ((inhibit-read-only t))
            (goto-char (point-min))
            (cond
             (fatal
              (insert (propertize (format "Boot threw: %s\n\n" (error-message-string fatal)) 'face 'error))
              (insert "This escaped all three isolation tiers - check *Messages*.\n")
              (local-set-key "q" #'quit-window))
             ((manifolding-emacs-errors-list)
              (insert (propertize "Boot completed with errors.\n\n" 'face 'error))
              (insert "Press RET or `C-c C-o' on a link to jump to it.\n")
              (insert "Press `t' to file the error at point to TODO, `T' for all.\n\n")
              (local-set-key "q" #'quit-window)
              (local-set-key "t" #'manifolding-emacs-splash-add-error-at-point)
              (local-set-key "T" #'manifolding-emacs-splash-add-all-errors))
             ((manifolding-emacs-warnings-list)
              (insert (propertize "Boot completed with warnings.\n\n" 'face 'warning))
              (local-set-key "q" #'quit-window))
             (t (ignore-errors (quit-windows-on buf)) (kill-buffer buf)))))))))

(provide 'manifolding-emacs)
;;; manifolding-emacs.el ends here
