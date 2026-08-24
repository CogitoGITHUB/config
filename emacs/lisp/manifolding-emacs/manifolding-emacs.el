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

(defun manifolding-emacs-reload (&optional force)
  "Recompile every Org file.
Unchanged files replay from the content-hash cache.  With FORCE
\(prefix argument) bypass the cache and recompile everything."
  (interactive "P")
  (manifolding-emacs-compile-directory nil force))

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
  (let ((manifolding-emacs--booting t) (fatal nil)
        (boot-t0 (float-time)))
    (setq manifolding-emacs-splash--state nil)
    (manifolding-emacs-errors-clear-boot-state)
    (when manifolding-emacs-mode-line-indicator (manifolding-emacs-doctor-indicator-mode 1))
    (condition-case err
        (manifolding-emacs-with-warning-capture
         (let ((buf (manifolding-emacs-show-splash)) (manifolding-emacs--boot-phase :compiling))
           ;; Immediate feedback: module scan + first compile take a
           ;; moment — never leave a blank screen wondering.
           (with-current-buffer buf
             (let ((inhibit-read-only t)
                   (org-mode-hook nil))
               (erase-buffer)
               (insert (manifolding-emacs-splash--center
                        "MANIFOLDING-EMACS\n\nreading modules/ …")))
             (redisplay))
           (let ((message-log-max nil))
             (message "Manifolding-Emacs: reading modules/"))
           (manifolding-emacs-compile-directory (manifolding-emacs--splash-progress buf))))
      (error (setq fatal err)))
    (manifolding-emacs-errors-save-log)
    (unless fatal
      (manifolding-emacs-maybe-freeze-on-clean-boot)
      (manifolding-emacs-doctor-schedule-idle-sweep))
    (message "manifolding-emacs: %s%d error(s), %d warning(s)" (if fatal "BOOT THREW - " "")
             (length (manifolding-emacs-errors-list)) (length (manifolding-emacs-warnings-list)))
    ;; Void-defun sweep: verify critical functions actually exist.
    ;; Catches "balanced but wrongly nested" paren bugs where defuns
    ;; end up inside other forms instead of at top level.
    (dolist (check
             '(("my/manifolding-atlas-org-prompt--ask" . "org-prompts.org")
               ("my/manifolding-atlas-collect-prompts" . "prompt-engine.org")
               ("my/manifolding-atlas-routines-run" . "routines.org")
               ("modaled-define-keys" . "keyboard.org (via modaled)")))
      (unless (fboundp (intern (car check)))
        (message "⚠ CRITICAL: %s is VOID — check %s for paren/nesting issues"
                 (car check) (cdr check))))
    ;; Paren-issue detector: if any error mentions parsing/unbalanced,
    ;; tell the user exactly what happened — no external tools needed.
    (dolist (e (manifolding-emacs-errors-list))
      (when (and (manifolding-emacs-error-entry-p e)
                 (manifolding-emacs-error-entry-message e)
                 (string-match-p
                  "UNBALANCED PARENS\\|End of file during parsing"
                  (manifolding-emacs-error-entry-message e)))
        (message
         "⚠ UNBALANCED PARENS — the error above shows the exact function and position. Fix the extra/missing closer and reload.")))
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
              (local-set-key "q" #'quit-window)
              (local-set-key "g"
                             (lambda () (interactive) (manifolding-emacs-reload))))
             (t
              ;; The dashboard must NEVER be able to kill init:
              ;; any error here is contained and the boot still
              ;; counts as clean.
              (condition-case dash-err
                  (manifolding-emacs-splash-clean-finish
                   buf (- (float-time) boot-t0))
                (error
                 (message "manifolding-emacs: dashboard error %s"
                          (error-message-string dash-err))))))))))))

(defvar manifolding-emacs--log-buffer-name "*Manifolding-Emacs*"
  "Buffer receiving loader chatter instead of *Messages*.")

(defun manifolding-emacs--redirect-message (orig fmt &rest args)
  "Route loader-prefixed chatter into its own buffer.
Any `message' whose format starts with \"manifolding-emacs:\" is
appended to `manifolding-emacs--log-buffer-name' and never reaches
*Messages*.  Errors and warnings keep their normal channels."
  (if (and (stringp fmt)
           (string-prefix-p "manifolding-emacs:" fmt))
      (progn
        (with-current-buffer (get-buffer-create
                              manifolding-emacs--log-buffer-name)
          (let ((inhibit-read-only t))
            (goto-char (point-max))
            (insert (apply #'format fmt args) "\n")))
        nil)
    (apply orig fmt args)))

(advice-add 'message :around #'manifolding-emacs--redirect-message)

(provide 'manifolding-emacs)
;;; manifolding-emacs.el ends here
