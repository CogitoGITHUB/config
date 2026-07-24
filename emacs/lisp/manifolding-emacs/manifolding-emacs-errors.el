;;; manifolding-emacs-errors.el --- Error tracking, recovery, reporting -*- lexical-binding: t; -*-

;;; Commentary:

;; Central nervous system.  Everything that can fail funnels through
;; here.  Three isolation tiers all report through this file:
;;
;;   part    a single :config/:init body, wrapped INTO the generated
;;           code itself (`manifolding-emacs-wrap-in-condition'), so
;;           the protection travels with it and still fires even if
;;           the body runs later via `:leaf-defer', long after boot.
;;   package one whole (leaf NAME ...) form's initial eval, wrapped by
;;           manifolding-emacs-compiler.el.  Catches immediate failures
;;           (bad :bind, bad :straight recipe, leaf itself erroring)
;;           that a part-level wrap alone wouldn't cover.
;;   file    one whole file's compile pipeline, wrapped by
;;           manifolding-emacs-compiler.el's directory loop.  Catches
;;           read/parse failures that happen before any package is
;;           even reached.
;;
;; A subtlety worth knowing: a part-level failure that happens
;; SYNCHRONOUSLY during boot (not deferred) would otherwise get
;; recorded twice — once by the baked-in part handler, once by the
;; package handler that also catches it.  `manifolding-emacs--inside-tier2-eval'
;; exists purely to avoid that: the part handler only self-records
;; when it's firing OUTSIDE that dynamic extent, i.e. only when it's
;; the sole thing left that will ever catch this failure.
;;
;; `manifolding-emacs--package-status' is the durable, cross-session
;; answer to "did this package actually load" — manifolding-emacs-doctor.el
;; is the UI on top of it.

;;; Code:

(require 'cl-lib)
(require 'manifolding-emacs-vars)

;;;; Data shape

(cl-defstruct (manifolding-emacs-error-entry
               (:constructor manifolding-emacs--make-error-entry))
  level file line package keyword message time)

(defvar manifolding-emacs--boot-errors '()
  "List of `manifolding-emacs-error-entry', most recent first.")

(defvar manifolding-emacs--boot-warnings '()
  "List of (:type TYPE :message MESSAGE :time TIME), most recent first.")

(defvar manifolding-emacs--package-status (make-hash-table :test 'equal)
  "PACKAGE-NAME (string) -> plist (:status 'ok|'error :file F :message M
:time TIME).  Persists across boots this session; only ever updated
per-package, never mass-cleared, so a partial reload doesn't erase
status for files it didn't touch.")

(defvar manifolding-emacs--inside-tier2-eval nil
  "Bound to t only during the synchronous per-package eval in
manifolding-emacs-compiler.el.  See Commentary above.")

;;;; Recording

(cl-defun manifolding-emacs-record-error (&key level file line package keyword message)
  "Record a failure and, unless still booting, surface it immediately."
  (let ((entry (manifolding-emacs--make-error-entry
                :level level :file file :line line :package package
                :keyword keyword :message message :time (float-time))))
    (push entry manifolding-emacs--boot-errors)
    (when package
      (manifolding-emacs-record-status package 'error file message))
    (unless manifolding-emacs--booting
      (display-warning
       'manifolding-emacs
       (format "%s%s%s: %s"
               (or file "") (if line (format ":%s" line) "")
               (if package (format " [%s]" package) "") message)
       :error))
    entry))

(defun manifolding-emacs-record-warning (type message)
  (push (list :type type :message message :time (float-time))
        manifolding-emacs--boot-warnings))

(defun manifolding-emacs-record-status (package-name status &optional file message)
  (puthash (format "%s" package-name)
           (list :status status :file file :message message :time (float-time))
           manifolding-emacs--package-status))

;;;; Read-only accessors

(defun manifolding-emacs-errors-list () manifolding-emacs--boot-errors)
(defun manifolding-emacs-warnings-list () manifolding-emacs--boot-warnings)

(defun manifolding-emacs-package-status (package-name)
  (gethash (format "%s" package-name) manifolding-emacs--package-status))

(defun manifolding-emacs-all-package-statuses ()
  (let (result)
    (maphash (lambda (k v) (push (cons k v) result)) manifolding-emacs--package-status)
    result))

(defun manifolding-emacs-errors-clear-boot-state ()
  "Clear the transient per-boot lists.  Does NOT touch
`manifolding-emacs--package-status' — see
`manifolding-emacs-errors-clear-all-status' for that."
  (setq manifolding-emacs--boot-errors '() manifolding-emacs--boot-warnings '()))

(defun manifolding-emacs-errors-clear-all-status ()
  "Wipe all recorded package statuses.  Manual escape hatch for when
your module set has changed enough that stale entries are more
confusing than useful."
  (interactive)
  (clrhash manifolding-emacs--package-status)
  (message "manifolding-emacs: cleared all package status history"))

;;;; Warning capture

(defun manifolding-emacs--warning-advice (type message &rest _)
  (manifolding-emacs-record-warning type message))

(defmacro manifolding-emacs-with-warning-capture (&rest body)
  "Run BODY with `display-warning' captured into
`manifolding-emacs--boot-warnings' instead of shown immediately."
  `(unwind-protect
       (progn (advice-add 'display-warning :before #'manifolding-emacs--warning-advice)
              ,@body)
     (advice-remove 'display-warning #'manifolding-emacs--warning-advice)))

;;;; Safe reading / part-level wrapping

(defun manifolding-emacs-safe-read (string file &optional line)
  "Read STRING, tagging any read error with FILE/LINE for context."
  (condition-case err
      (read string)
    (error
     (signal 'error
             (concat (if line (format "Read error in %s:%s" file line)
                       (format "Read error in %s" file))
                     ": " (error-message-string err))))))

(defun manifolding-emacs-wrap-in-condition (file part &optional package keyword)
  "Wrap PART's body in `condition-case', baked into the returned code so
protection travels with it through deferred execution.  Used only for
:config/:init parts — see `manifolding-emacs-validate-loose-block' for
top-level statements, which never need this since they always run
synchronously and the caller's own handler is enough."
  (let* ((body (plist-get part :body))
         (line (plist-get part :line))
         (expression-string (string-trim-right body))
         (expression (manifolding-emacs-safe-read
                      (format "(progn\n%s\n)" expression-string) file line)))
    (if manifolding-emacs-wrap-statements-in-condition
        (pp-to-string
         `(condition-case err
              ,expression
            (error
             (unless manifolding-emacs--inside-tier2-eval
               (manifolding-emacs-record-error
                :level 'part :file ,(format "%s" file) :line ,line
                :package ,(and package (format "%s" package))
                :keyword ,keyword
                :message (error-message-string err)))
             (signal (car err) (cdr err)))))
      expression-string)))

(defun manifolding-emacs-validate-loose-block (file part)
  "Validate a loose (non-package) block's syntax at build time and
return its trimmed body string.  Unlike `manifolding-emacs-wrap-in-condition'
this does NOT bake in a recorder: loose blocks always run synchronously
at compile time, so the caller's own `condition-case' around eval is
sufficient and avoids recording the same failure twice."
  (let* ((body (plist-get part :body))
         (line (plist-get part :line))
         (expression-string (string-trim-right body)))
    (manifolding-emacs-safe-read (format "(progn\n%s\n)" expression-string) file line)
    expression-string))

;;;; Filing to TODO.org

(defun manifolding-emacs--error-heading (entry)
  (format "** TODO Fix: %s%s"
          (if (manifolding-emacs-error-entry-file entry)
              (car (last (split-string (manifolding-emacs-error-entry-file entry) "/")))
            "(no file)")
          (if (manifolding-emacs-error-entry-package entry)
              (format " (%s)" (manifolding-emacs-error-entry-package entry))
            "")))

(defun manifolding-emacs-add-error-to-todo (entry)
  "Append ENTRY to `manifolding-emacs-todo-file' as a TODO item."
  (unless (file-exists-p manifolding-emacs-todo-file)
    (user-error "TODO file not found at %s" manifolding-emacs-todo-file))
  (with-current-buffer (find-file-noselect manifolding-emacs-todo-file)
    (widen)
    (goto-char (point-max))
    (insert (format "\n%s\n" (manifolding-emacs--error-heading entry)))
    (insert (format "Error from manifolding-emacs boot (%s), level %s:\n"
                    (format-time-string "%Y-%m-%d") (manifolding-emacs-error-entry-level entry)))
    (when (manifolding-emacs-error-entry-file entry)
      (insert (format "[[file:%s::%s][%s:%s]]\n"
                       (manifolding-emacs-error-entry-file entry)
                       (or (manifolding-emacs-error-entry-line entry) 1)
                       (manifolding-emacs-error-entry-file entry)
                       (or (manifolding-emacs-error-entry-line entry) 1))))
    (insert (format "%s\n" (manifolding-emacs-error-entry-message entry)))
    (save-buffer)))

(defun manifolding-emacs-error-under-point ()
  "Return the error entry linked at point in a splash/doctor buffer."
  (save-excursion
    (beginning-of-line)
    (when (looking-at "^[[:space:]]*\u231e")
      (forward-line -1) (beginning-of-line))
    (when (looking-at "^\\[\\[file:\\([^]]+\\)::\\([0-9]+\\)")
      (let ((file (match-string-no-properties 1))
            (line (string-to-number (match-string-no-properties 2))))
        (cl-find-if (lambda (e) (and (equal (manifolding-emacs-error-entry-file e) file)
                                      (eql (manifolding-emacs-error-entry-line e) line)))
                    manifolding-emacs--boot-errors)))))

(defun manifolding-emacs-splash-add-error-at-point ()
  (interactive)
  (let ((e (manifolding-emacs-error-under-point)))
    (if e (progn (manifolding-emacs-add-error-to-todo e)
                 (message "Error added to %s" manifolding-emacs-todo-file))
      (user-error "No error found at point"))))

(defun manifolding-emacs-splash-add-all-errors ()
  (interactive)
  (if (not manifolding-emacs--boot-errors)
      (user-error "No errors to add")
    (dolist (e manifolding-emacs--boot-errors) (manifolding-emacs-add-error-to-todo e))
    (message "All %d errors added to %s" (length manifolding-emacs--boot-errors)
             manifolding-emacs-todo-file)))

;;;; Persistence

(defun manifolding-emacs--entry-to-plist (entry)
  (list :level (manifolding-emacs-error-entry-level entry)
        :file (manifolding-emacs-error-entry-file entry)
        :line (manifolding-emacs-error-entry-line entry)
        :package (manifolding-emacs-error-entry-package entry)
        :keyword (manifolding-emacs-error-entry-keyword entry)
        :message (manifolding-emacs-error-entry-message entry)
        :time (manifolding-emacs-error-entry-time entry)))

(defun manifolding-emacs-errors-save-log ()
  "Persist this session's errors/warnings/status as one readable form."
  (interactive)
  (let ((data (list :errors (mapcar #'manifolding-emacs--entry-to-plist manifolding-emacs--boot-errors)
                     :warnings manifolding-emacs--boot-warnings
                     :status (manifolding-emacs-all-package-statuses)
                     :saved-at (current-time-string))))
    (with-temp-file manifolding-emacs-error-log-file
      (insert ";; -*- lisp-data -*-\n;; manifolding-emacs error log. Read, don't hand-edit.\n")
      (pp data (current-buffer)))))

(defun manifolding-emacs-errors-load-log ()
  "Read back the persisted log, or nil if there isn't one yet."
  (when (file-exists-p manifolding-emacs-error-log-file)
    (with-temp-buffer
      (insert-file-contents manifolding-emacs-error-log-file)
      (goto-char (point-min))
      (condition-case nil (progn (forward-line 2) (read (current-buffer)))
        (error nil)))))

(provide 'manifolding-emacs-errors)
;;; manifolding-emacs-errors.el ends here
