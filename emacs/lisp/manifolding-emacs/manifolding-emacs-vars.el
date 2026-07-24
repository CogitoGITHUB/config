;;; manifolding-emacs-vars.el --- Core variables and utilities -*- lexical-binding: t; -*-

;;; Commentary:

;; Foundation layer: defcustoms, defvars, directory resolution, small
;; dependency-free utilities.  Every other manifolding-emacs-*.el file
;; requires this one, directly or transitively; this file requires none
;; of them.

;;; Code:

(defgroup manifolding-emacs nil
  "A literate, org-based Emacs package manager built on leaf and straight."
  :group 'emacs
  :prefix "manifolding-emacs-")

;;;; Package-macro configuration

(defcustom manifolding-emacs-package-method 'leaf
  "Method to use for package management."
  :type '(choice (const :tag "use-package" use-package)
                 (const :tag "use-package!" use-package!)
                 (const :tag "leaf" leaf))
  :group 'manifolding-emacs)

(defcustom manifolding-emacs-wrap-statements-in-condition t
  "Wrap :config/:init bodies in `condition-case', baked into the
generated code itself.  This is what lets one broken package fail
without taking the rest of your config down with it, and what lets
that protection still work even when the body runs later via
`:leaf-defer' — long after boot's own error handling has gone out of
scope.  Disable only for debugging; `manifolding-emacs-preview' does
this locally so the expansion it shows is easier to read."
  :type 'boolean
  :group 'manifolding-emacs)

(defcustom manifolding-emacs-package-keywords-extra
  '(:straight :general :ghook :gfhook :general-config)
  "Extra keywords beyond the active macro's own canonical set.
Keywords already present in that canonical set are ignored here (see
`manifolding-emacs-package-keywords' in
manifolding-emacs-package-builder.el) — this is only for keywords the
macro doesn't already know about."
  :type '(repeat symbol)
  :group 'manifolding-emacs)

(defcustom manifolding-emacs-condition-case-keywords
  '(:config :init)
  "Keywords whose body gets wrapped in `condition-case'."
  :type '(repeat symbol)
  :group 'manifolding-emacs)

(defcustom manifolding-emacs-leaf-force-require 'auto
  "Whether to force `:require t' onto every leaf package.

- t     Always append it (the old, unconditional behavior).
- nil   Never append it; trust leaf's own deferral entirely.
- auto  Append it only when the package has no deferring keyword of
        its own (:bind :bind* :hook :mode :interpreter :magic
        :magic-fallback :commands :after) and no explicit :require
        already — i.e. only when nothing else would ever load it.

`auto' is the default because unconditionally forcing :require t
silently defeats `:leaf-defer' for every single package, which is the
single biggest lever leaf gives you for boot-time cost."
  :type '(choice (const t) (const nil) (const auto))
  :group 'manifolding-emacs)

;;;; Directories

(defcustom manifolding-emacs-org-directory (expand-file-name "org" user-emacs-directory)
  "Directory where the Org files are stored."
  :type 'string :group 'manifolding-emacs)

(defcustom manifolding-emacs-output-directory (expand-file-name "manifolding-emacs" user-emacs-directory)
  "Directory where tangled/aggregated output is written."
  :type 'string :group 'manifolding-emacs)

(defcustom manifolding-emacs-remote-org-directory (expand-file-name "remote-org" user-emacs-directory)
  "Directory where downloaded remote Org files are cached."
  :type 'string :group 'manifolding-emacs)

(defcustom manifolding-emacs-remote-output-directory (expand-file-name "remote-manifolding-emacs" user-emacs-directory)
  "Directory where remote-file output is written."
  :type 'string :group 'manifolding-emacs)

(defcustom manifolding-emacs-todo-file (expand-file-name "modules/TODO.org" user-emacs-directory)
  "Org file that boot errors get filed to by
`manifolding-emacs-add-error-to-todo'."
  :type 'string :group 'manifolding-emacs)

(defcustom manifolding-emacs-error-log-file (expand-file-name "manifolding-emacs-errors.log.el" user-emacs-directory)
  "Where the structured boot error/warning/status log is persisted, as
a single readable Elisp form (not human prose) so it can be read back
with `read' next session."
  :type 'string :group 'manifolding-emacs)

;;;; Behavior toggles

(defcustom manifolding-emacs-force-compile nil
  "Force recompilation even if output looks up to date."
  :type 'boolean :group 'manifolding-emacs)

(defcustom manifolding-emacs-force-download nil
  "Force re-download of remote Org files even if already present."
  :type 'boolean :group 'manifolding-emacs)

(defcustom manifolding-emacs-default-profile nil
  "Straight profile symbol used for files with no #+PROFILE: property.
Only meaningful if you've configured `straight-profiles' yourself;
manifolding-emacs never defines profiles, it only tells straight which
one is active while a given file's packages register."
  :type '(choice (const nil) symbol) :group 'manifolding-emacs)

(defcustom manifolding-emacs-idle-sweep-enabled t
  "If non-nil, force-require every known package a few seconds after
boot finishes, so a deferred-load error surfaces immediately instead
of whenever you happen to trigger that package."
  :type 'boolean :group 'manifolding-emacs)

(defcustom manifolding-emacs-idle-sweep-delay 8
  "Idle seconds to wait after boot before the doctor sweep runs.  Kept
out of the critical boot path on purpose: this only affects when
errors get discovered, never how fast Emacs starts."
  :type 'number :group 'manifolding-emacs)

(defcustom manifolding-emacs-mode-line-indicator t
  "If non-nil, show a package-health segment in the mode line."
  :type 'boolean :group 'manifolding-emacs)

;;;; Dynamic / working state

(defvar manifolding-emacs-packages nil
  "Working plist of package-name -> keyword-plist for whatever is
currently being compiled.  Always dynamically `let'-bound around a
compile pass; never meaningful at top level.")

(defvar manifolding-emacs-compiling-remote nil
  "Non-nil while compiling a file pulled from
`manifolding-emacs-remote-org-directory'; changes which directory pair
`manifolding-emacs-get-org-directory'/`manifolding-emacs-get-output-directory'
resolve to.")

(defvar manifolding-emacs--booting nil
  "Non-nil for the duration of `manifolding-emacs-boot'.")

(defvar manifolding-emacs--boot-phase :loading
  "Current boot phase, `:compiling' or `:loading', for splash labeling.")

;;;; Generic utilities

(defun manifolding-emacs-indent (string n)
  "Indent every line of STRING by N spaces."
  (let ((indentation (make-string n ?\s)))
    (replace-regexp-in-string "^" indentation string)))

(defun manifolding-emacs-plist-keys (plist)
  "Return the keys of PLIST, in order."
  (let (keys)
    (while plist
      (push (car plist) keys)
      (setq plist (cddr plist)))
    (nreverse keys)))

(defun manifolding-emacs-get-org-directory ()
  "Return the active Org source directory."
  (if manifolding-emacs-compiling-remote
      (expand-file-name manifolding-emacs-remote-org-directory)
    (expand-file-name manifolding-emacs-org-directory)))

(defun manifolding-emacs-get-output-directory ()
  "Return the active output directory."
  (if manifolding-emacs-compiling-remote
      (expand-file-name manifolding-emacs-remote-output-directory)
    (expand-file-name manifolding-emacs-output-directory)))

(provide 'manifolding-emacs-vars)
;;; manifolding-emacs-vars.el ends here
