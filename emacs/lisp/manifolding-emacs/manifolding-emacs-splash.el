;;; manifolding-emacs-splash.el --- Boot splash screen -*- lexical-binding: t; -*-

;;; Commentary:

;; Pure renderer: reads `manifolding-emacs-errors-list' and
;; `manifolding-emacs-warnings-list', never mutates them.  All
;; state-changing work (recording, filing to TODO, clearing) lives in
;; manifolding-emacs-errors.el.

;;; Code:

(require 'manifolding-emacs-vars)
(require 'manifolding-emacs-errors)

(defun manifolding-emacs-show-splash ()
  (let ((buf (get-buffer-create "*Manifolding-Emacs*")))
    (with-current-buffer buf (erase-buffer) (let ((org-mode-hook nil)) (org-mode)))
    (switch-to-buffer buf)
    buf))

(defun manifolding-emacs-progress-bar (current total width)
  (let* ((ratio (if (zerop total) 1.0 (/ (float current) total)))
         (done (floor (* ratio width))) (todo (- width done)))
    (format "[%s%s]" (make-string done ?#) (make-string todo ?.))))

(defun manifolding-emacs-progress-bar-fancy (current total width)
  (let* ((ratio (if (zerop total) 1.0 (/ (float current) total)))
         (done (floor (* ratio width))) (todo (- width done)))
    (format "\u250c%s\u2510\n\u2502%s%s\u2502\n\u2514%s\u2518"
            (make-string width ?\u2500) (make-string done ?\u2588)
            (make-string todo ?\u00b7) (make-string width ?\u2500))))

(defun manifolding-emacs-splash-update-progress (buf current total file)
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (let ((inhibit-read-only t)
            (label (pcase manifolding-emacs--boot-phase
                     (:compiling "Compiling") (:loading "Loading") (_ "Processing")))
            (errors (manifolding-emacs-errors-list))
            (warnings (manifolding-emacs-warnings-list)))
        (erase-buffer)
        (insert "MANIFOLDING-EMACS\n\n")
        (insert (format "[ %d / %d ]\n\n" current total))
        (insert (manifolding-emacs-progress-bar-fancy current total 54))
        (insert "\n\n")
        (insert (if file (format "%s: %s\n" label file) "\n"))
        (center-region (point-min) (point-max))
        (when errors
          (insert "\nErrors encountered:\n\n")
          (dolist (e (reverse errors))
            (if (manifolding-emacs-error-entry-file e)
                (insert (format "[[file:%s::%s][%s:%s]]\n"
                                 (manifolding-emacs-error-entry-file e)
                                 (or (manifolding-emacs-error-entry-line e) 1)
                                 (manifolding-emacs-error-entry-file e)
                                 (or (manifolding-emacs-error-entry-line e) 1)))
              (insert (format "%s\n" (manifolding-emacs-error-entry-level e))))
            (insert (propertize (format " \u231e %s\n" (manifolding-emacs-error-entry-message e)) 'face 'error))))
        (when warnings
          (insert "\nWarnings encountered:\n\n")
          (dolist (w (reverse warnings))
            (insert (propertize (format " * %s: %s\n" (plist-get w :type) (plist-get w :message)) 'face 'warning))))
        (redisplay)
        (unless file (let ((org-mode-hook nil)) (org-mode)))))))

(provide 'manifolding-emacs-splash)
;;; manifolding-emacs-splash.el ends here
