;;; manifolding-emacs-doctor.el --- Package health dashboard -*- lexical-binding: t; -*-

;;; Commentary:

;; Answers "is everything actually OK?" without you having to go
;; trigger every package by hand.  `manifolding-emacs-doctor' shows
;; every known package's status; the idle sweep force-`require's every
;; one of them a few seconds after boot so deferred-load errors
;; surface immediately instead of the next time you use the package.

;;; Code:

(require 'cl-lib)
(require 'tabulated-list)
(require 'manifolding-emacs-vars)
(require 'manifolding-emacs-errors)
(require 'manifolding-emacs-org-parse)
(require 'manifolding-emacs-compiler)

(defun manifolding-emacs-doctor--known-packages ()
  "Alist of (package-name . file) for every package declared anywhere
under the active Org directory, regardless of whether it ever
successfully compiled."
  (let (result)
    (dolist (file (manifolding-emacs-get-files "^[^#]*\\.org$" (manifolding-emacs-get-org-directory)))
      (unless (manifolding-emacs-file-disabled-p file)
        (dolist (name (manifolding-emacs-file-package-names file))
          (push (cons name file) result))))
    (nreverse result)))

(defun manifolding-emacs-doctor--collect-rows ()
  (let (rows)
    (dolist (pair (manifolding-emacs-doctor--known-packages))
      (let* ((name (car pair)) (file (cdr pair)) (status (manifolding-emacs-package-status name)))
        (push (list name (vector (format "%s" name)
                                  (if status (format "%s" (plist-get status :status)) "never-attempted")
                                  (or (and status (plist-get status :file)) (format "%s" file))
                                  (or (and status (plist-get status :message)) "")))
              rows)))
    (dolist (e (manifolding-emacs-errors-list))
      (unless (manifolding-emacs-error-entry-package e)
        (push (list nil (vector (format "(%s)" (manifolding-emacs-error-entry-level e)) "error"
                                 (or (manifolding-emacs-error-entry-file e) "")
                                 (manifolding-emacs-error-entry-message e)))
              rows)))
    (nreverse rows)))

(defvar manifolding-emacs-doctor-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map "g" #'manifolding-emacs-doctor-refresh)
    (define-key map "r" #'manifolding-emacs-doctor-retry-at-point)
    map))

(define-derived-mode manifolding-emacs-doctor-mode tabulated-list-mode "Manifolding-Doctor"
  "Major mode listing every known package's load status."
  (setq tabulated-list-format [("Package" 28 t) ("Status" 16 t) ("File" 40 t) ("Message" 0 nil)])
  (setq tabulated-list-sort-key (cons "Status" nil))
  (tabulated-list-init-header))

(defun manifolding-emacs-doctor-refresh ()
  (interactive)
  (setq tabulated-list-entries (manifolding-emacs-doctor--collect-rows))
  (tabulated-list-print t))

(defun manifolding-emacs-doctor-retry-at-point ()
  "Recompile just the package at point and refresh the table."
  (interactive)
  (let ((name (tabulated-list-get-id)))
    (if (not name)
        (user-error "This row isn't a retriable package")
      (let ((file (alist-get name (manifolding-emacs-doctor--known-packages) nil nil #'equal)))
        (if (not file)
            (user-error "Can't find the source file for %s" name)
          (manifolding-emacs-recompile-package file name)
          (manifolding-emacs-doctor-refresh))))))

;;;###autoload
(defun manifolding-emacs-doctor ()
  "Open the package health dashboard."
  (interactive)
  (let ((buf (get-buffer-create "*Manifolding-Doctor*")))
    (with-current-buffer buf (manifolding-emacs-doctor-mode) (manifolding-emacs-doctor-refresh))
    (switch-to-buffer buf)))

(defun manifolding-emacs-doctor--mode-line-string ()
  (let ((broken (cl-count-if (lambda (p) (eq (plist-get (cdr p) :status) 'error))
                             (manifolding-emacs-all-package-statuses))))
    (if (zerop broken) ""
      (propertize (format " \u26a0%d" broken) 'face 'error
                  'help-echo "manifolding-emacs: packages with load errors - M-x manifolding-emacs-doctor"
                  'mouse-face 'mode-line-highlight
                  'local-map (make-mode-line-mouse-map 'mouse-1 #'manifolding-emacs-doctor)))))

(define-minor-mode manifolding-emacs-doctor-indicator-mode
  "Global minor mode showing a package-health segment in the mode line."
  :global t :group 'manifolding-emacs
  (let ((segment '(:eval (manifolding-emacs-doctor--mode-line-string))))
    (setq global-mode-string
          (if manifolding-emacs-doctor-indicator-mode
              (append (remove segment global-mode-string) (list segment))
            (remove segment global-mode-string)))))

(defvar manifolding-emacs-doctor--idle-timer nil)

(defun manifolding-emacs-doctor--force-require-one (package-name)
  "Force-`require' PACKAGE-NAME so a deferred load error surfaces now.
Assumes the org PACKAGE name is also its require-able feature symbol —
leaf's own convention, true for the overwhelming majority of packages."
  (condition-case err
      (progn (require (intern (format "%s" package-name)) nil t)
             (manifolding-emacs-record-status package-name 'ok))
    (error (manifolding-emacs-record-error :level 'package :package package-name
                                            :message (format "idle sweep: %s" (error-message-string err))))))

(defun manifolding-emacs-doctor-sweep-now ()
  "Force-require every known package immediately (not on a timer)."
  (interactive)
  (dolist (pair (manifolding-emacs-doctor--known-packages))
    (manifolding-emacs-doctor--force-require-one (car pair)))
  (message "manifolding-emacs: idle sweep complete"))

(defun manifolding-emacs-doctor-schedule-idle-sweep ()
  "Run `manifolding-emacs-doctor-sweep-now' once,
`manifolding-emacs-idle-sweep-delay' idle-seconds from now, if enabled.
Call once, at the end of `manifolding-emacs-boot'."
  (when (and manifolding-emacs-idle-sweep-enabled (not manifolding-emacs-doctor--idle-timer))
    (setq manifolding-emacs-doctor--idle-timer
          (run-with-idle-timer manifolding-emacs-idle-sweep-delay nil
                                (lambda () (setq manifolding-emacs-doctor--idle-timer nil)
                                  (manifolding-emacs-doctor-sweep-now))))))

(provide 'manifolding-emacs-doctor)
;;; manifolding-emacs-doctor.el ends here
