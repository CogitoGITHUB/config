;;; manifolding-emacs-compiler.el --- Compile Org files to running config -*- lexical-binding: t; -*-

;;; Commentary:

;; The engine.  Packages are read and eval'd ONE AT A TIME (never
;; concatenated into one blob the way the original design did) — that's
;; what makes per-package isolation possible at all.  See
;; manifolding-emacs-errors.el's commentary for the three-tier model.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'org)
(require 'org-element)
(require 'ob-core)
(require 'manifolding-emacs-vars)
(require 'manifolding-emacs-errors)
(require 'manifolding-emacs-org-parse)
(require 'manifolding-emacs-package-builder)
(require 'manifolding-emacs-remote)

;; straight.el's dynamic variable; declared so the byte-compiler
;; doesn't warn about binding it when straight isn't loaded yet.
(defvar straight-current-profile)

(defcustom manifolding-emacs-lexical-binding t
  "When non-nil, every module block/package is evaluated with lexical
binding.  Lexical compilation makes closures capture their environment
correctly and drastically reduces interpreter stack depth
\(max-lisp-eval-depth pressure).  Set to nil only to roll back to the
legacy dynamic-binding behavior."
  :type 'boolean)

(defun manifolding-emacs-concatenate-source-blocks (file)
  "Populate `manifolding-emacs-packages' from FILE.  Return the list of
loose (non-package) top-level statements as validated, trimmed
strings, in file order."
  (with-temp-buffer
    (insert-file-contents file)
    (let (org-mode-hook) (org-mode))
    (let ((keywords (manifolding-emacs-package-keywords))
          (results '()))
      ;; Pass 1: headline PROPERTY keywords, e.g. :STRAIGHT:, :DISABLED:
      (org-map-entries
       (lambda ()
         (let ((package-name (manifolding-emacs-find-package)))
           (dolist (key keywords)
             (when-let* ((body (manifolding-emacs-find-property-string key)))
               (when (or (not (eq key :straight))
                         (manifolding-emacs-validate-straight-recipe
                          body package-name file (line-number-at-pos)))
                 (manifolding-emacs-put-package-parameter
                  package-name key `((:body ,body :line ,(line-number-at-pos))))))))))
      ;; Pass 2: fold a :DEPENDS: property into the :straight recipe
      (org-map-entries
       (lambda ()
         (when-let* ((package-name (manifolding-emacs-find-package))
                     (depends-body (manifolding-emacs-find-property-string :depends))
                     (straight-entry (plist-get (plist-get manifolding-emacs-packages package-name) :straight))
                     (straight-body (plist-get (car straight-entry) :body)))
           (condition-case err
               (let ((recipe (read straight-body)) (depends (read depends-body)))
                 (when (listp depends)
                   (manifolding-emacs-put-package-parameter
                    package-name :straight
                    `((:body ,(prin1-to-string (append recipe (list :depends depends)))
                             :line ,(plist-get (car straight-entry) :line))))))
             (error
              (manifolding-emacs-record-error
               :level 'package :file file :package package-name :keyword :depends
               :line (line-number-at-pos)
               :message (format "failed to parse :DEPENDS: %s" (error-message-string err))))))))
      ;; Pass 3: emacs-lisp source blocks -> package keyword body, or a
      ;; loose top-level statement
      (org-babel-map-src-blocks nil
        (let* ((element (org-element-context))
               (body (org-element-property :value element))
               (line (line-number-at-pos (org-element-property :begin element)))
               (language (org-element-property :language element))
               (params (org-element-property :parameters element))
               (tangle (when params (cdr (assq :tangle (org-babel-parse-header-arguments params))))))
          (when (and (string= language "emacs-lisp") (not (equal tangle "no")))
            (if-let* ((package (manifolding-emacs-get-use-package-package keywords)))
                (let* ((package-name (car package))
                       (parameter (intern (concat ":" (cadr package))))
                       (previous (plist-get (plist-get manifolding-emacs-packages package-name) parameter)))
                  (manifolding-emacs-put-package-parameter
                   package-name parameter (append previous `((:body ,body :line ,line)))))
              (when (stringp body)
                (push (manifolding-emacs-validate-loose-block file (list :body body :line line))
                      results))))))
      (nreverse results))))

(defun manifolding-emacs--eval-package-string (package-name package-string file)
  "Read and eval PACKAGE-STRING in isolation: a failure marks
PACKAGE-NAME as errored instead of propagating to its siblings."
  (condition-case err
      (progn
        (let ((manifolding-emacs--inside-tier2-eval t))
          (eval (manifolding-emacs-safe-read
                 (format "(progn\n%s\n)" package-string) file)
                manifolding-emacs-lexical-binding))
        (manifolding-emacs-record-status package-name 'ok file))
    (error
     (manifolding-emacs-record-error :level 'package :file file :package package-name
                                      :message (error-message-string err)))))

(defun manifolding-emacs-compile-packages (file)
  "Build and individually eval every package `manifolding-emacs-packages'
currently knows about."
  (dolist (package-name (manifolding-emacs-plist-keys manifolding-emacs-packages))
    (when-let* ((package-string (manifolding-emacs-build-package file package-name)))
      (manifolding-emacs--eval-package-string package-name package-string file))))

;;; Compile Cache
;; Content-hash cache: parse each Org module ONCE per version, replay
;; the exact same eval units from a serialized cache afterwards.  The
;; cache stores the ordered PARTS (loose forms + package bodies) that
;; compile-file would have produced, so evaluation semantics — per-part
;; isolation included — are byte-identical to a fresh compile.

(defconst manifolding-emacs-cache-salt "3"
  "Bump to invalidate every cached module after loader changes.")

(defun manifolding-emacs-cache-dir ()
  (expand-file-name "module-cache/"
                    (expand-file-name ".local/cache/" user-emacs-directory)))

(defun manifolding-emacs-cache-path (key)
  (expand-file-name (concat key ".cache.el")
                    (manifolding-emacs-cache-dir)))

(defun manifolding-emacs-cache-key (file)
  (secure-hash
   'sha256
   (concat manifolding-emacs-cache-salt "\0"
           (or (condition-case nil
                   (with-temp-buffer
                     (insert-file-contents-literally file)
                     (buffer-string))
                 (error ""))
               "")
           "\0" (symbol-name manifolding-emacs-lexical-binding))))

(defun manifolding-emacs--cache-read (path)
  (condition-case nil
      (car (read-from-string
            (with-temp-buffer
              (insert-file-contents path)
              (buffer-string))))
    (error nil)))

(defun manifolding-emacs--cache-write (path data)
  (make-directory (file-name-directory path) t)
  ;; print-length/print-level MUST be nil here: a bound value would
  ;; truncate the serialized parts and silently corrupt the entry.
  (let ((print-length nil)
        (print-level nil))
    (with-temp-file path
      (insert ";; manifolding-emacs module cache\n"
              (prin1-to-string data)))))

(defun manifolding-emacs--extract-parts (file)
  "Return (PARTS . PROFILE) mirroring compile-file's eval units.
PARTS is an ordered list of (:kind part|package [:name N] :body S):
all loose forms in document order, followed by package bodies."
  (let* ((manifolding-emacs-packages nil)
         (profile (manifolding-emacs-file-profile file))
         (straight-current-profile
          (or profile (and (boundp 'straight-current-profile)
                           straight-current-profile)))
         (loose-forms (manifolding-emacs-concatenate-source-blocks file))
         (parts (mapcar (lambda (s) (list :kind 'part :body s))
                        loose-forms))
         (package-parts nil))
    (dolist (package-name
             (manifolding-emacs-plist-keys manifolding-emacs-packages))
      (when-let* ((package-string
                   (manifolding-emacs-build-package file package-name)))
        (push (list :kind 'package :name package-name :body package-string)
              package-parts)))
    (cons (append parts (nreverse package-parts)) profile)))

(defun manifolding-emacs--eval-parts (file parts profile &optional signal-error)
  "Evaluate PARTS with the same isolation compile-file provides.
When SIGNAL-ERROR is non-nil, the first part error is recorded AND
re-signaled, so callers can fall back to a fresh compile."
  (let ((straight-current-profile
         (or profile (and (boundp 'straight-current-profile)
                          straight-current-profile))))
    (dolist (part parts)
      (let* ((is-package (eq (plist-get part :kind) 'package))
             (body (plist-get part :body)))
        (condition-case err
            (progn
              (let ((manifolding-emacs--inside-tier2-eval t))
                (eval (manifolding-emacs-safe-read
                       (format "(progn\n%s\n)" body) file)
                      manifolding-emacs-lexical-binding))
              (when is-package
                (manifolding-emacs-record-status
                 (plist-get part :name) 'ok file)))
          (error
           (if is-package
               (manifolding-emacs-record-error
                :level 'package :file file
                :package (plist-get part :name)
                :line 1
                :message (error-message-string err))
             (manifolding-emacs-record-error
              :level 'part :file file
              :message (format "%s :: %S"
                               (error-message-string err)
                               (substring body 0 (min 120 (length body)))))))
           (when signal-error
             (signal (car err) (cdr err))))))))

(defun manifolding-emacs-compile-file-cached (file &optional force)
  "Compile FILE through the content-hash cache.
FORCE non-nil skips the cache and refreshes the entry.  Returns FILE,
or nil when the file is disabled."
  (unless (file-exists-p file)
    (error "File to compile does not exist: %s" file))
  (if (manifolding-emacs-file-disabled-p file)
      (progn
        (message "manifolding-emacs: skipping disabled file %s"
                 (file-name-nondirectory file))
        nil)
    (let* ((key (manifolding-emacs-cache-key file))
           (path (manifolding-emacs-cache-path key))
           (cached (and (not force)
                        (file-exists-p path)
                        (manifolding-emacs--cache-read path)))
           (parts (plist-get cached :parts))
           (profile (plist-get cached :profile)))
      (if (and (consp parts) cached)
          (condition-case replay-err
              (progn
                (manifolding-emacs--eval-parts file parts profile 'signal)
                file)
            (error
             ;; Corrupt/stale entry: drop it and fall back to a fresh
             ;; compile so the session can never inherit a broken cache.
             (ignore-errors (delete-file path))
             (message "manifolding-emacs: cache fallback for %s (%s)"
                      (file-name-nondirectory file)
                      (error-message-string replay-err))
             (pcase-let* ((`(,fparts . ,fprofile)
                           (manifolding-emacs--extract-parts file)))
               (condition-case nil
                   (manifolding-emacs--cache-write
                    path (list :version manifolding-emacs-cache-salt
                               :profile fprofile :parts fparts))
                 (error nil))
               (manifolding-emacs--eval-parts file fparts fprofile)
               file)))
        (pcase-let* ((`(,parts . ,profile)
                      (manifolding-emacs--extract-parts file)))
          (condition-case nil
              (manifolding-emacs--cache-write
               path (list :version manifolding-emacs-cache-salt
                          :profile profile
                          :parts parts))
            (error nil))
          (manifolding-emacs--eval-parts file parts profile)
          file)))))

(defun manifolding-emacs-compile-file (file)
  "Compile FILE.  Returns FILE, or nil if skipped (disabled).
Does NOT itself catch errors escaping extraction — callers handle
that.  Always bypasses the cache: this entry point means \"the user
just touched this file\"."
  (unless (file-exists-p file)
    (error "File to compile does not exist: %s" file))
  (if (manifolding-emacs-file-disabled-p file)
      (progn
        (message "manifolding-emacs: skipping disabled file %s"
                 (file-name-nondirectory file))
        nil)
    (message "manifolding-emacs: compiling %s"
             (file-name-nondirectory file))
    (pcase-let* ((`(,parts . ,profile)
                  (manifolding-emacs--extract-parts file)))
      (manifolding-emacs--eval-parts file parts profile)
      file)))

(defun manifolding-emacs-recompile-package (file package-name)
  "Re-extract FILE and (re-)eval only PACKAGE-NAME, leaving every other
package in FILE untouched.  Used by `manifolding-emacs-doctor'."
  (interactive)
  (let ((manifolding-emacs-packages nil))
    (manifolding-emacs-concatenate-source-blocks file)
    (if-let* ((package-string (manifolding-emacs-build-package file package-name)))
        (progn (manifolding-emacs--eval-package-string package-name package-string file)
               (message "manifolding-emacs: retried %s -> %s" package-name
                        (plist-get (manifolding-emacs-package-status package-name) :status)))
      (user-error "No such package `%s' in %s" package-name file))))

(defun manifolding-emacs-compile-directory (&optional progress-fn force)
  "Compile every Org file under the active Org directory.
Unchanged files replay from the content-hash cache; FORCE bypasses it.
If PROGRESS-FN is given, call it with (CURRENT TOTAL FILE) before
compiling each file — used to drive a splash screen without this file
knowing anything about UI."
  (let* ((files (manifolding-emacs-get-files "^[^#]*\\.org$" (manifolding-emacs-get-org-directory)))
         (compiled '()) (current 0) (total (length files)))
    (dolist (file files)
      (setq current (1+ current))
      (when progress-fn (funcall progress-fn current total file))
      (when-let* ((remote-plist (manifolding-emacs-file-remote file)))
        (manifolding-emacs-pull-remote-file remote-plist))
      (condition-case err
          (when-let* ((output (manifolding-emacs-compile-file-cached file force)))
            (push output compiled))
        (error (manifolding-emacs-record-error :level 'file :file file
                                               :message (error-message-string err)))))
    (nreverse compiled)))

(defun manifolding-emacs-aggregate-directory (output-file)
  "Concatenate every Org file's raw contents into OUTPUT-FILE."
  (let (result)
    (dolist (file (manifolding-emacs-get-files "^[^#]*\\.org$" (manifolding-emacs-get-org-directory)))
      (push (with-temp-buffer (insert-file-contents file) (buffer-string)) result))
    (with-temp-file output-file (insert (mapconcat #'identity (nreverse result) "\n")))))

(defun manifolding-emacs-output-file-name (file)
  "The .el path FILE would tangle to, if you ever wanted to tangle to
disk instead of eval'ing directly."
  (if (string-prefix-p (manifolding-emacs-get-org-directory) (expand-file-name file))
      (expand-file-name
       (concat (file-name-as-directory (manifolding-emacs-get-output-directory))
               (file-name-sans-extension
                (substring (expand-file-name file) (length (manifolding-emacs-get-org-directory))))
               ".el"))
    (error "File is not under the active Org directory")))

(provide 'manifolding-emacs-compiler)
;;; manifolding-emacs-compiler.el ends here
