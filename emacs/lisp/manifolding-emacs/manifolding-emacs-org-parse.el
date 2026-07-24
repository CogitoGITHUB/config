;;; manifolding-emacs-org-parse.el --- Org-tree introspection -*- lexical-binding: t; -*-

;;; Commentary:

;; Readers over Org buffers/files.  Nothing here mutates
;; `manifolding-emacs-packages' or evaluates anything.  Functions that
;; need the active macro's keyword set take it as an argument instead
;; of asking manifolding-emacs-package-builder.el directly, so this
;; file has no dependency on it.

;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'subr-x)
(require 'org)
(require 'manifolding-emacs-vars)

(defun manifolding-emacs-find-property (property)
  "Find PROPERTY on the current Org element or nearest ancestor."
  (save-excursion
    (condition-case nil
        (progn
          (while (not (org-element-property property (org-element-context)))
            (org-up-element))
          (intern (org-element-property property (org-element-context))))
      (error nil))))

(defun manifolding-emacs-find-tags ()
  (save-excursion
    (condition-case nil
        (progn
          (while (not (org-element-property :tags (org-element-lineage (org-element-context) '(headline) t)))
            (org-up-element))
          (org-element-property :tags (org-element-lineage (org-element-context) '(headline) t)))
      (error nil))))

(defun manifolding-emacs-find-tag (keywords)
  "KEYWORDS is the active macro's ordered keyword list."
  (let ((tag (car (seq-filter (lambda (tag) (member (intern (concat ":" tag)) keywords))
                              (manifolding-emacs-find-tags)))))
    (when tag
      (replace-regexp-in-string "_" "-" (replace-regexp-in-string "_$" "*" tag)))))

(defun manifolding-emacs-find-package ()
  (or (manifolding-emacs-find-property :PACKAGE)
      (manifolding-emacs-find-property :USE_PACKAGE)
      (manifolding-emacs-find-property :USE-PACKAGE)
      (manifolding-emacs-find-property :LEAF)))

(defun manifolding-emacs-find-property-string (key)
  (when-let* ((value (or (manifolding-emacs-find-property (intern (downcase (format "%s" key))))
                          (manifolding-emacs-find-property (intern (upcase (format "%s" key))))))
              (str (and value (symbol-name value))))
    (prin1-to-string (read str))))

(defun manifolding-emacs-find-keyword ()
  (when-let* ((keyword (manifolding-emacs-find-property :KEYWORD)))
    (replace-regexp-in-string "^:" "" (symbol-name keyword))))

(defun manifolding-emacs-get-use-package-package (keywords)
  "Return (PACKAGE-NAME PARAMETER) for the current source block, or nil."
  (when-let* ((package (manifolding-emacs-find-package)))
    (list package (or (manifolding-emacs-find-keyword)
                      (manifolding-emacs-find-tag keywords)
                      "config"))))

(defun manifolding-emacs-file-properties (file)
  "Return the #+KEY: value file-level properties of FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (let (org-mode-hook) (org-mode))
    (let (properties)
      (goto-char (point-min))
      (while (re-search-forward "^\\(?:;;[ \t]*\\)?#\\+\\([A-Za-z0-9_]+\\):[ \t]*\\(.*\\)$" nil t)
        (push (cons (intern (downcase (match-string 1))) (match-string 2)) properties))
      properties)))

(defun manifolding-emacs-file-priority (file)
  (let ((priority (alist-get 'priority (manifolding-emacs-file-properties file) "10")))
    (if (string-match-p "^[0-9]+$" priority) (string-to-number priority) 10)))

(defun manifolding-emacs-file-remote (file)
  (when-let* ((remote (alist-get 'remote (manifolding-emacs-file-properties file))))
    (read remote)))

(defun manifolding-emacs-file-lexical-binding (file)
  (not (equal (alist-get 'lexical_binding (manifolding-emacs-file-properties file) "t") "nil")))

(defun manifolding-emacs-file-disabled-p (file)
  (alist-get 'disabled (manifolding-emacs-file-properties file)))

(defun manifolding-emacs-file-profile (file)
  "Return FILE's #+PROFILE: as a symbol, or `manifolding-emacs-default-profile'."
  (let ((profile (alist-get 'profile (manifolding-emacs-file-properties file))))
    (if profile (intern (string-trim profile)) manifolding-emacs-default-profile)))

(defun manifolding-emacs-file-package-names (file)
  "Distinct package names declared anywhere in FILE.  Cheaper than
`manifolding-emacs-concatenate-source-blocks': just enumerates names,
for auditing (see manifolding-emacs-doctor.el)."
  (with-temp-buffer
    (insert-file-contents file)
    (let (org-mode-hook) (org-mode))
    (let (names)
      (org-map-entries (lambda () (when-let* ((name (manifolding-emacs-find-package)))
                                     (cl-pushnew name names))))
      (nreverse names))))

(defun manifolding-emacs-get-files (extension directory)
  "Return all files matching EXTENSION under DIRECTORY, priority-sorted."
  (if (file-directory-p directory)
      (let ((files (directory-files-recursively directory extension)))
        (sort files (lambda (a b) (< (manifolding-emacs-file-priority a)
                                      (manifolding-emacs-file-priority b)))))
    (progn (message "manifolding-emacs: directory does not exist: %s" directory) nil)))

(provide 'manifolding-emacs-org-parse)
;;; manifolding-emacs-org-parse.el ends here
