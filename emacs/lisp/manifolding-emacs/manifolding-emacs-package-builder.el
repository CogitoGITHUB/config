;;; manifolding-emacs-package-builder.el --- Package-form codegen -*- lexical-binding: t; -*-

;;; Commentary:

;; Turns the plist accumulated in `manifolding-emacs-packages' into an
;; actual `(leaf NAME ...)' / `(use-package NAME ...)' form, as a
;; string.  Doesn't evaluate anything — manifolding-emacs-compiler.el
;; owns the eval step and its own tier-2 isolation around it.

;;; Code:

(require 'cl-lib)
(require 'manifolding-emacs-vars)
(require 'manifolding-emacs-errors)

(declare-function leaf-available-keywords "leaf")
(defvar use-package-keywords)

(defun manifolding-emacs-package-keywords ()
  "Return the ordered keyword list for the active package macro.
Preserves the macro's own canonical order — this matters, because leaf
relies on that order for correctness (e.g. `:disabled' has to stay
first to short-circuit everything after it).  Extras from
`manifolding-emacs-package-keywords-extra' the macro doesn't already
know about are appended at the end, never interleaved."
  (let ((base (pcase manifolding-emacs-package-method
                ('leaf (when (and (require 'leaf nil t) (fboundp 'leaf-available-keywords))
                         (leaf-available-keywords)))
                ((or 'use-package 'use-package!)
                 (when (and (require 'use-package-core nil t) (boundp 'use-package-keywords))
                   use-package-keywords))
                (_ '()))))
    (append base (cl-remove-if (lambda (k) (memq k base)) manifolding-emacs-package-keywords-extra))))

(defun manifolding-emacs-put-package-parameter (package-name parameter value)
  (setq manifolding-emacs-packages
        (plist-put manifolding-emacs-packages package-name
                   (plist-put (plist-get manifolding-emacs-packages package-name) parameter value))))

(defun manifolding-emacs-merge-bodies (file xs)
  "Merge the :body entries of XS (a list of (:body S :line N)) into one form."
  (let (result)
    (dolist (x xs)
      (when-let* ((parsed (manifolding-emacs-safe-read (plist-get x :body) file (plist-get x :line))))
        (setq result (append result parsed))))
    (when result (prin1-to-string result))))

(defun manifolding-emacs-validate-straight-recipe (recipe-string package-name file line)
  "Return t for allowed :type (built-in, local, file, git, or anything
with explicit :host/:repo); record an error and return nil otherwise."
  (condition-case err
      (let* ((recipe (read recipe-string))
             (recipe-type (plist-get (cdr recipe) :type)))
        (cond
         ((memq recipe-type '(built-in file local git)) t)
         (recipe-type
          (manifolding-emacs-record-error
           :level 'package :file file :line line :package package-name :keyword :straight
           :message (format ":type %s is not allowed (use git, file, local, or built-in)" recipe-type))
          nil)
         ((or (plist-get (cdr recipe) :host) (plist-get (cdr recipe) :repo)) t)
         (t
          (manifolding-emacs-record-error
           :level 'package :file file :line line :package package-name :keyword :straight
           :message "recipe has no :type and no :host/:repo (would default to MELPA)")
          nil)))
    (error
     (manifolding-emacs-record-error
      :level 'package :file file :line line :package package-name :keyword :straight
      :message (format "error reading straight recipe: %s" (error-message-string err)))
     nil)))

(defun manifolding-emacs-build-package-string (package-name package file)
  (let* ((package-macro (pcase manifolding-emacs-package-method
                          ('leaf "leaf") ('use-package! "use-package!") (_ "use-package")))
         (keys (manifolding-emacs-package-keywords))
         (body-parts
          (delq nil
                (mapcar
                 (lambda (key)
                   (unless (eq key :package)
                     (when-let* ((entry (plist-get package key)))
                       (format "\n  %s\n%s" key
                               (manifolding-emacs-indent
                                (string-join
                                 (mapcar (lambda (part)
                                           (if (member key manifolding-emacs-condition-case-keywords)
                                               (manifolding-emacs-wrap-in-condition file part package key)
                                             (plist-get part :body)))
                                         entry)
                                 "\n")
                                2)))))
                 keys))))
    (string-trim-right
     (concat (format "(%s %s" package-macro package-name) (apply #'concat body-parts) ")\n\n"))))

(defun manifolding-emacs--package-has-defer-keyword-p (package)
  (cl-some (lambda (k) (plist-get package k))
           '(:bind :bind* :hook :mode :interpreter :magic :magic-fallback :commands :after)))

(defun manifolding-emacs--should-force-require (package)
  (pcase manifolding-emacs-leaf-force-require
    ('t t)
    ('nil nil)
    (_ (and (not (plist-get package :require))
            (not (manifolding-emacs--package-has-defer-keyword-p package))))))

(defun manifolding-emacs--append-require-t (package-string)
  (let* ((trimmed (string-trim-right package-string)) (pos (1- (length trimmed))))
    (concat (substring trimmed 0 pos) "\n  :require t)\n\n")))

(defun manifolding-emacs-build-package (file package-name)
  (when-let* ((package (plist-get manifolding-emacs-packages package-name)))
    (unless (equal package-name (intern "nil"))
      (let ((package-string (manifolding-emacs-build-package-string package-name package file)))
        (when (manifolding-emacs-safe-read package-string file)
          (if (and (eq manifolding-emacs-package-method 'leaf)
                   (manifolding-emacs--should-force-require package))
              (manifolding-emacs--append-require-t package-string)
            package-string))))))

(defun manifolding-emacs-build-packages (file)
  "Build every package's string and concatenate them.  Used only by
`manifolding-emacs-preview' — the real compile pipeline builds and
evals packages one at a time for per-package isolation instead."
  (mapconcat (lambda (name) (or (manifolding-emacs-build-package file name) ""))
             (manifolding-emacs-plist-keys manifolding-emacs-packages) ""))

(provide 'manifolding-emacs-package-builder)
;;; manifolding-emacs-package-builder.el ends here
