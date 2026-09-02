(defun my/manifolding-atlas-templates-dir ()
  "Return the templates directory."
  (expand-file-name "Manifolding-Emacs/modules/manifolding-atlas/blueprints/templates/"
                    user-emacs-directory))

(defun my/manifolding-atlas-template-files-dir ()
  "Alias for `my/manifolding-atlas-templates-dir'."
  (my/manifolding-atlas-templates-dir))

(defvar my/manifolding-atlas-prompt-registry nil
  "List of prompt specs. Each spec is a plist with:
:key           SYMBOL   — unique identifier (same as :name)
:name          SYMBOL   — unique identifier (alias for :key)
:label         STRING   — human-readable display name for Transient UI
:prompt-fn     FUNCTION — (&optional current) -> raw value from the user
:contexts      LIST     — '(file heading task ...)
:to-plist      FUNCTION — (VAL CONTEXT) -> plist fragment
:read-current-fn FUNCTION — () -> current value from the visited buffer
:validate-fn   FUNCTION or nil — (VAL) -> non-nil means valid
:merge-strategy SYMBOL  — 'replace | 'merge | 'append

Fragment keys:
:tags         (list of strings)      — merged by append
:properties   (alist)                — merged by append
:body         (string)               — concatenated
:post-apply   (list of functions)    — each called with the note
:after        nil or 'last           — heading insert position")

;; Reset on every config load so prompts don't accumulate duplicates
(setq my/manifolding-atlas-prompt-registry nil)

(defun my/manifolding-atlas-register-prompt (&rest plist)
  "Register a prompt spec PLIST into `my/manifolding-atlas-prompt-registry'.
If :key is missing, copies :name into :key for backward compat."
  (unless (plist-get plist :key)
    (setq plist (plist-put plist :key (plist-get plist :name))))
  (unless (plist-get plist :name)
    (setq plist (plist-put plist :name (plist-get plist :key))))
  (push plist my/manifolding-atlas-prompt-registry))

;;; manifolding-atlas.el --- Note management library for Org mode -*- lexical-binding: t; -*-
;;
;; Copyright (c) 2015-2026 Boris Buliga <boris@d12frosted.io>
;;
;; Author: Boris Buliga <boris@d12frosted.io>
;; Maintainer: Boris Buliga <boris@d12frosted.io>
;; Version: 2.5.0
;; Package-Requires: ((emacs "29.1") (org "9.4.4") (emacsql "4.3.0") (s "1.12") (dash "2.19"))
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see
;; <http://www.gnu.org/licenses/>.
;;
;; Created: 08 Jan 2021
;;
;; URL: https://github.com/d12frosted/vulpea
;;
;; License: GPLv3
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Manifolding Atlas is a note management library for Org mode that maintains its
;; own SQLite database for efficient querying and organization.
;;
;; Key features:
;; - Fast note lookup via SQLite database with automatic sync
;; - Rich note structure: titles, aliases, tags, links, properties, metadata
;; - Flexible querying by tags, links, properties, dates, and more
;; - Metadata system using Org description lists
;; - Note creation with customizable templates
;; - Selection interface with filtering and alias expansion
;;
;; Quick start:
;;   (setq manifolding-atlas-directory "~/org/")
;;   (manifolding-atlas-db-sync-start)
;;
;; Main entry points:
;; - `manifolding-atlas-find' - find and open a note
;; - `manifolding-atlas-insert' - insert a link to a note
;; - `manifolding-atlas-create' - create a new note
;; - `manifolding-atlas-db-query' - query notes with a predicate
;; - `manifolding-atlas-select' - select a note with completion
;;
;; See https://github.com/d12frosted/vulpea for documentation.
;;
;;; Code:

(require 'package)
(require 'org-capture)
(require 'org-id)
(require 's)

(declare-function elpaca-get "ext:elpaca" (id))
(declare-function elpaca-source-dir "ext:elpaca" (e))
(declare-function elpaca<-repo-dir "ext:elpaca" (e))
(declare-function straight--repos-dir "ext:straight" (&rest segments))

(defconst manifolding-atlas-version "2.5.0"
  "Version of the manifolding-atlas package.

Keep in sync with the Version header in manifolding-atlas.el; releases bump
both. For precise version information including commits past a
release, use the function `manifolding-atlas-version' instead.")

(defun manifolding-atlas-version--git ()
  "Return version from \"git describe\", or nil if unavailable.

Works when manifolding-atlas is loaded from a git checkout and git is
available. The result looks like \"v2.2.0\" exactly on a release
tag, \"v2.2.0-15-g2938416\" when 15 commits past it, with a
\"-dirty\" suffix when there are uncommitted changes.

The checkout is searched in several places, because package
managers separate the loaded build from the git source: the
resolved truename of the loaded library (plain checkouts, and
managers that symlink their build directory), then elpaca's and
straight's source directories when those managers are present
\(their builds are plain copies, revealing nothing about the
checkout)."
  (when-let* ((dir (seq-some
                    (lambda (candidate)
                      (and candidate
                           (locate-dominating-file candidate ".git")))
                    (list
                     (when-let* ((file (locate-library "manifolding-atlas")))
                       (file-truename file))
                     (when (fboundp 'elpaca-get)
                       (when-let* ((e (elpaca-get 'manifolding-atlas)))
                         (cond
                          ((fboundp 'elpaca-source-dir)
                           (elpaca-source-dir e))
                          ((fboundp 'elpaca<-repo-dir)
                           (elpaca<-repo-dir e)))))
                     (when (fboundp 'straight--repos-dir)
                       (straight--repos-dir "manifolding-atlas")))))
              ((executable-find "git")))
    (with-temp-buffer
      (let ((default-directory dir))
        (when (eql 0 (ignore-errors
                       (call-process "git" nil t nil "describe"
                                     "--tags" "--dirty" "--always")))
          (string-trim (buffer-string)))))))

(defun manifolding-atlas-version--package ()
  "Return version of the installed manifolding-atlas package, or nil.

For MELPA snapshot installs the result looks like
\"20260610.1234 (commit 2938416)\"."
  (when-let* ((desc (cadr (assq 'manifolding-atlas package-alist)))
              (version (package-version-join
                        (package-desc-version desc))))
    (if-let* ((commit (cdr (assq :commit (package-desc-extras desc)))))
        (format "%s (commit %s)"
                version (substring commit 0 (min 7 (length commit))))
      version)))

(defun manifolding-atlas-version (&optional show)
  "Return the manifolding-atlas version with as much precision as available.

The version is resolved in the following order:

1. \"git describe\" output when running from a git checkout,
   e.g. \"v2.2.0\" or \"v2.2.0-15-g2938416\".
2. Installed package version, including the commit for MELPA
   snapshot installs, e.g. \"20260610.1234 (commit 2938416)\".
3. The `manifolding-atlas-version' constant as a fallback.

When SHOW is non-nil (always when called interactively), also
display the version in the echo area. Please include this
version in bug reports."
  (interactive (list t))
  (let ((version (or (manifolding-atlas-version--git)
                     (manifolding-atlas-version--package)
                     manifolding-atlas-version)))
    (when show
      (message "manifolding-atlas %s" version))
    version))

;;; Doctor

(defun manifolding-atlas-doctor--db-file-info ()
  "Return a human-readable description of the database file."
  (if (file-exists-p manifolding-atlas-db-location)
      (format "exists (%s)"
              (file-size-human-readable
               (file-attribute-size
                (file-attributes manifolding-atlas-db-location))))
    "missing"))

(defun manifolding-atlas-doctor--note-count ()
  "Return the number of indexed notes, or nil when unavailable.

Returns nil instead of creating the database file when it does
not exist - the doctor must not modify state."
  (when (file-exists-p manifolding-atlas-db-location)
    (ignore-errors (manifolding-atlas-db-count-notes))))

(defun manifolding-atlas-doctor--cached-file-stats ()
  "Return (TOTAL . NOTE-LESS) file change-detection cache counts.

TOTAL is how many files are tracked in the `files' table; NOTE-LESS
is how many of them have no note in the `notes' table.  A non-zero
NOTE-LESS is expected for genuinely note-less files (READMEs,
drafts), but a surprising count can indicate notes that failed to
index and are now skipped by change detection (see manifolding-atlas#277);
`manifolding-atlas-db-sync-full-scan' with a force argument re-extracts them.

Returns nil when the database file is absent; does not create it."
  (when (file-exists-p manifolding-atlas-db-location)
    (ignore-errors
      (let ((db (manifolding-atlas-db)))
        (cons
         (caar (emacsql db [:select (funcall count *) :from files]))
         (caar (emacsql db
                        [:select (funcall count *) :from files
                         :where (not (in path
                                         [:select :distinct [path]
                                          :from notes]))])))))))

(defun manifolding-atlas-doctor--monitoring-status ()
  "Return a string describing the active external file monitoring."
  (cond
   ((and manifolding-atlas-db-sync--fswatch-process
         (process-live-p manifolding-atlas-db-sync--fswatch-process))
    "fswatch (process running)")
   (manifolding-atlas-db-sync--poll-timer
    (format "polling (every %ss)" manifolding-atlas-db-sync-poll-interval))
   (t "none")))

(defun manifolding-atlas-doctor (&optional show)
  "Diagnose the Manifolding Atlas setup and return a report string.

The report covers versions, configuration, database state, sync
state, external tool availability, and a list of detected issues.
It is read-only: nothing is created or modified, even when the
database does not exist yet. Please include the report in bug
reports.

When SHOW is non-nil (always when called interactively), also
display the report in the *manifolding-atlas-doctor* buffer."
  (interactive (list t))
  (let ((report (manifolding-atlas-doctor--report)))
    (when show
      (with-current-buffer (get-buffer-create "*manifolding-atlas-doctor*")
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert report)
          (goto-char (point-min)))
        (special-mode)
        (display-buffer (current-buffer))))
    report))

;;; Customization

(defgroup manifolding-atlas nil
  "Manifolding Atlas note-taking system."
  :group 'org)

(defcustom manifolding-atlas-default-notes-directory nil
  "Default directory for creating new notes.

When nil (the default), dynamically resolves to the first entry in
`manifolding-atlas-db-sync-directories', which itself defaults to
`org-directory'.

Set this explicitly only if you want notes created in a different
directory than the first sync directory."
  :type '(choice (const :tag "Use first sync directory" nil)
                 (directory :tag "Explicit directory"))
  :group 'manifolding-atlas)

(defcustom manifolding-atlas-create-default-function nil
  "Function to compute default parameters for note creation.
Called with (title) and should return a plist of default parameters.
When nil, uses `manifolding-atlas-create-default-template' instead.

The function allows dynamic parameter computation based on context:

  (setq manifolding-atlas-create-default-function
        (lambda (title)
          (list :tags (if (string-match-p \"TODO\" title)
                          \\='(\"task\" \"inbox\")
                        \\='(\"note\" \"inbox\"))
                :head (format \"#+created: %s\"
                              (format-time-string \"[%Y-%m-%d]\"))
                :properties (list (cons \"SOURCE\"
                                        (buffer-name))))))

Parameters explicitly passed to `manifolding-atlas-create' override these defaults.

These defaults seed file-level note creation only.  When
`manifolding-atlas-create' is called with a non-nil `:parent' (a heading-level
note), this function is not called and no defaults are applied."
  :type '(choice (const :tag "Use template instead" nil)
          (function :tag "Function returning plist"))
  :group 'manifolding-atlas)

#+begin_src emacs-lisp
(defcustom manifolding-atlas-create-default-template
  '(:file-name "${timestamp}_${slug}.org")
  "Default template (plist) for note creation.
Only used when `manifolding-atlas-create-default-function' is nil.
Parameters explicitly passed to `manifolding-atlas-create' override these defaults.

These defaults seed file-level note creation only.  When
`manifolding-atlas-create' is called with a non-nil `:parent' (a heading-level
note), no defaults are consulted and the heading is built solely
from the explicitly passed arguments.

Supports all template expansion features:
  ${var}     - Variable substitution
  %(elisp)   - Elisp evaluation
  %<format>  - Timestamp formatting

Default configuration:
  \\='(:file-name \"${timestamp}_${slug}.org\")

Example customization:

  (setq manifolding-atlas-create-default-template
        \\='(:file-name \"inbox/${slug}.org\"
          :tags (\"fleeting\")
          :head \"#+created: %<[%Y-%m-%d]>\"
          :properties ((\"CREATED\" . \"%<[%Y-%m-%d]>\")
                       (\"AUTHOR\" . \"%(user-full-name)\"))
          :context (:source \"manual\")))

Note: %(elisp) and %<format> directives are honored only inside
the template fields themselves (e.g. :head, :properties values).
Context values are inserted literally and are not re-evaluated.

Available parameters:
  :file-name   - File name template (relative to default directory)
                 Can also be a function: (lambda (title) ...)
  :tags        - List of tag strings
  :head        - Header content after #+filetags
  :body        - Note body content
  :properties  - Alist of (key . value) for property drawer
  :meta        - Alist of (key . value) for metadata
  :context     - Plist of custom template variables

Template variables for :file-name:
  ${title}     - Note title
  ${slug}      - URL-friendly version of title
  ${timestamp} - Current timestamp (%Y%m%d%H%M%S)
  ${id}        - Note ID (UUID)"
  :type 'plist
  :group 'manifolding-atlas)

;;; Variables

(defvar manifolding-atlas-db-sync-directories)  ; Defined in manifolding-atlas-db

(defvar manifolding-atlas-find-default-filter nil
  "Default filter to use in `manifolding-atlas-find'.")

(defvar manifolding-atlas-find-default-candidates-source #'manifolding-atlas-db-query
  "Default source to get the list of candidates in `manifolding-atlas-find'.

Must be a function that accepts one argument - optional note
filter function.")

(defvar manifolding-atlas-find-default-create-fn #'manifolding-atlas-find-create-note
  "Default function to create a note in `manifolding-atlas-find'.

Called with two arguments - the title typed by the user and
capture properties (currently always nil, reserved for future
use) - mirroring the CREATE-FN argument of `manifolding-atlas-insert'. It
should create the note and return the resulting `manifolding-atlas-note' to
visit, or nil to skip visiting (e.g. when creation is interactive,
asynchronous, or was aborted).

This is the hook for \"capture on empty\" workflows: set it to a
function that routes to `org-capture' or your own command to turn
a fruitless search straight into note creation.")

;;; Helper Functions

(defun manifolding-atlas-title-to-slug (title)
  "Convert TITLE to URL-friendly slug.

Uses Unicode normalization to properly handle international characters
and diacritical marks. Implementation adapted from org-roam.

Credits: USAMI Kenta (@zonuexe)
See: https://github.com/org-roam/org-roam/pull/1460"
  (require 'ucs-normalize)
  (let ((slug-trim-chars
         ;; Combining Diacritical Marks https://www.unicode.org/charts/PDF/U0300.pdf
         ;; For why these specific glyphs: https://github.com/org-roam/org-roam/pull/1460
         '( #x300 #x301 #x302 #x303 #x304 #x306 #x307
            #x308 #x309 #x30A #x30B #x30C #x31B #x323
            #x324 #x325 #x327 #x32D #x32E #x330 #x331)))
    (thread-last title
                 (ucs-normalize-NFD-string) ;; aka. `string-glyph-decompose' from Emacs 29
                 (seq-remove (lambda (char) (memq char slug-trim-chars)))
                 (apply #'string)
                 (ucs-normalize-NFC-string) ;; aka. `string-glyph-compose' from Emacs 29
                 (replace-regexp-in-string "[^[:alnum:]]" "_") ;; convert anything not alphanumeric
                 (replace-regexp-in-string "__*" "_")          ;; remove sequential underscores
                 (replace-regexp-in-string "^_" "")            ;; remove starting underscore
                 (replace-regexp-in-string "_$" "")            ;; remove ending underscore
                 (downcase))))

(define-obsolete-function-alias 'manifolding-atlas--title-to-slug #'manifolding-atlas-title-to-slug "2.0.0")

;;; Link Categorization

(defun manifolding-atlas--get-incoming-links-with-descriptions (note-id)
  "Get all links pointing to NOTE-ID with their descriptions.
Returns list of plists with :source-id :source-path :pos :description."
  (let* ((links (manifolding-atlas-db-query-links-to note-id))
         ;; Collect unique source IDs and batch fetch for paths
         (source-ids (delete-dups (mapcar (lambda (l) (plist-get l :source)) links)))
         (source-notes (manifolding-atlas-db-query-by-ids source-ids))
         ;; Build id->path lookup table
         (id-to-path (make-hash-table :test 'equal))
         result)
    (dolist (note source-notes)
      (puthash (manifolding-atlas-note-id note) (manifolding-atlas-note-path note) id-to-path))
    ;; Process links - description comes from database now
    (dolist (link links)
      (let* ((source-id (plist-get link :source))
             (source-path (gethash source-id id-to-path)))
        (when source-path
          (push (list :source-id source-id
                      :source-path source-path
                      :pos (plist-get link :pos)
                      :description (plist-get link :description))
                result))))
    (nreverse result)))

(defun manifolding-atlas--categorize-links (links old-title)
  "Categorize LINKS into exact and partial matches.
Case-insensitive matching against OLD-TITLE.
Returns plist (:exact :partial).

Exact matches: description equals old title (case-insensitive).
Partial matches: description contains old title but isn't exact.
Links using aliases are left unchanged (alias is still valid).
Links with nil descriptions or custom descriptions are excluded."
  (let ((exact '())
        (partial '())
        (title-down (downcase old-title)))
    (dolist (link links)
      (let ((desc (plist-get link :description)))
        (when desc
          (let ((desc-down (downcase desc)))
            (cond
             ;; Exact match (case-insensitive)
             ((string= desc-down title-down)
              (push link exact))
             ;; Partial match - contains but not exact
             ((string-match-p (regexp-quote title-down) desc-down)
              (push link partial)))))))
    (list :exact (nreverse exact)
          :partial (nreverse partial))))

(defun manifolding-atlas--update-link-description (file pos new-description)
  "Update link description at POS in FILE to NEW-DESCRIPTION.
Works for both bare links [[id:xxx]] and links with
descriptions [[id:xxx][old]]."
  (with-current-buffer (find-file-noselect file)
    (save-excursion
      (goto-char pos)
      (cond
       ;; Link with existing description: [[id:xxx][old]]
       ((looking-at "\\(\\[\\[id:[^]]+\\]\\)\\[\\([^]]*\\)\\]\\]")
        (let ((link-part (match-string 1)))
          ;; LITERAL (3rd arg) so backslashes in NEW-DESCRIPTION are not
          ;; interpreted as match-group backreferences.
          (replace-match (concat link-part "[" new-description "]]") t t)))
       ;; Bare link without description: [[id:xxx]]
       ((looking-at "\\(\\[\\[id:[^]]+\\)\\]\\]")
        (let ((link-part (match-string 1)))
          (replace-match (concat link-part "][" new-description "]]") t t)))))))

(defun manifolding-atlas--default-directory ()
  "Return the default directory for creating new notes.

Resolution order:
  1. `manifolding-atlas-default-notes-directory' if set
  2. First directory from `manifolding-atlas-db-sync-directories' if set
  3. `org-directory' as fallback"
  (or manifolding-atlas-default-notes-directory
      (car manifolding-atlas-db-sync-directories)
      org-directory))

(defun manifolding-atlas--expand-file-name-template (title &optional id template context)
  "Expand file name template with TITLE, ID, TEMPLATE, and CONTEXT.
If TEMPLATE is nil, uses `:file-name' from `manifolding-atlas-create-default-template'.
CONTEXT is a plist of additional template variables.
Returns absolute file path."
  (let* ((template (or template
                       (plist-get manifolding-atlas-create-default-template :file-name)
                       "${slug}.org"))  ; Absolute fallback
         (template-resolved (if (functionp template)
                                (funcall template title)
                              template))
         (file-name (manifolding-atlas--expand-template template-resolved title id context))
         (dir (manifolding-atlas--default-directory)))
    (expand-file-name file-name dir)))

(defun my/manifolding-atlas--insert-body-template (template-name)
  "Insert body template TEMPLATE-NAME into current buffer.
TEMPLATE-NAME is a filename without extension from templates/files."
  (let* ((template-file (expand-file-name
                         (concat template-name ".org")
                         (my/manifolding-atlas-template-files-dir)))
         (content (when (file-exists-p template-file)
                    (with-temp-buffer
                      (insert-file-contents template-file)
                      (buffer-string)))))
    (when content
      (goto-char (point-max))
      (insert content))))

(defun manifolding-atlas--format-note-content (id title &optional head meta tags properties)
  "Format note content for `org-capture' template.

ID and TITLE are required. Optional: HEAD, META (alist), TAGS (list),
PROPERTIES (alist)."
  (string-join
   (append
    (list
     (format "* %s" title)
     ":PROPERTIES:"
     (format org-property-format ":ID:" id))
    (mapcar
     (lambda (prop)
       (format org-property-format
               (concat ":" (car prop) ":")
               (cdr prop)))
     properties)
    (list
     ":END:")
    (when tags
      (list (concat "#+filetags: :"
                    (string-join tags ":")
                    ":")))
    (when head (list head))
    (when meta
      (list ""))  ; blank line before meta
    (when meta
      (mapcar
       (lambda (kvp)
         (if (listp (cdr kvp))
             (mapconcat
              (lambda (val)
                (concat "- " (car kvp) " :: " (manifolding-atlas-buffer-meta-format val)))
              (cdr kvp) "\n")
           (concat "- " (car kvp) " :: " (manifolding-atlas-buffer-meta-format (cdr kvp)))))
       meta)))
   "\n"))

(defun my/manifolding-atlas--all-warning-defaults (context)
  "Return a :properties alist WARNING-defaulting every registered
prompt whose :contexts include CONTEXT (a symbol like 'file).
Reuses the existing per-kind fragment logic so each property is
built the same way the normal picker would build it -- just with
WARNING as the value instead of an interactive answer."
  (when (zerop (hash-table-count my/manifolding-atlas-org-prompt--specs))
    (my/manifolding-atlas-org-prompt--register-all))
  (let ((acc (list (cons "TODO_STATE" "WARNING"))))
    (dolist (entry my/manifolding-atlas-prompt-registry)
      (let ((key-sym (plist-get entry :name))
            (contexts (plist-get entry :contexts)))
        (when (memq context contexts)
          (let ((spec (gethash key-sym my/manifolding-atlas-org-prompt--specs)))
            (when (and spec (not (eq (plist-get spec :kind) 'todo)))
              (let* ((key (plist-get spec :key))
                     (kind (plist-get spec :kind))
                     (plist (plist-get spec :plist)))
                (condition-case nil
                    (let ((frag (my/manifolding-atlas-org-prompt--fragment
                                 key kind plist "WARNING")))
                      (when frag
                        (setq acc (append acc (plist-get frag :properties)))))
                  (error nil))))))))
    acc))

(defun manifolding-atlas-find-create-note (title &optional _props)
  "Create a new note with TITLE selected in `manifolding-atlas-find'.

Prompts for slug, subdir. Creates the file immediately so tags and
aliases have somewhere to go. Then prompts for alias, tags, body
template and applies them to the open buffer.

TITLE is already collected by `manifolding-atlas-find' before this
function runs.

Creates a file-level note via `manifolding-atlas-create' and returns the
resulting `manifolding-atlas-note'. PROPS mirrors the capture properties
argument of `manifolding-atlas-insert' CREATE-FN and is currently unused.

This is the default value of `manifolding-atlas-find-default-create-fn'."
  (let* ((fname (my/manifolding-atlas-prompt-file-name title nil))
         (subdir (my/manifolding-atlas-prompt-subdir))
         (default-props (my/manifolding-atlas--all-warning-defaults 'file))
         (note (manifolding-atlas-create title fname
                           :properties default-props)))
     (find-file (manifolding-atlas-note-path note))
     (let* ((alias (my/manifolding-atlas-prompt-aliases))
            (tags (my/manifolding-atlas-org-prompt--ask-tags nil)))
       (when alias
         (org-entry-put nil "ALIAS" (mapconcat #'identity alias ", ")))
       (goto-char (point-min))
       (when (re-search-forward "^\\* " nil t)
         (goto-char (match-end 0))
         (insert "TODO ")
         (when tags
           (end-of-line)
           (insert (concat " :" (mapconcat #'identity tags ":") ":"))))
(let ((template (my/manifolding-atlas-prompt-template--choose)))
          (when (and template (not (member template '("WARNING" "none"))))
            (my/manifolding-atlas--insert-body-template template))))
     note))

(defun my/manifolding-atlas--get-template-content (template-name)
  "Return content of TEMPLATE-NAME or nil."
  (when (and template-name (not (member template-name '("WARNING" "none"))))
    (let ((template-file (expand-file-name
                           (concat template-name ".org")
                           (expand-file-name "files" (my/manifolding-atlas-template-files-dir)))))
      (when (file-exists-p template-file)
        (with-temp-buffer
          (insert-file-contents template-file)
          (buffer-string))))))

(defun manifolding-atlas-find-create-note (title &optional _props)
  "Create a new note with TITLE selected in `manifolding-atlas-find'.

Prompts for slug, subdir. Creates file and opens in org-capture.
Then prompts for alias, tags. Finally shows live template preview
in the capture buffer as you navigate options - finalize to keep
working in the buffer.

TITLE is already collected by `manifolding-atlas-find' before this
function runs.

Creates a file-level note via `manifolding-atlas-create' and returns the
resulting `manifolding-atlas-note'. PROPS mirrors the capture properties
argument of `manifolding-atlas-insert' CREATE-FN and is currently unused.

This is the default value of `manifolding-atlas-find-default-create-fn'."
  (let* ((fname (my/manifolding-atlas-prompt-file-name title nil))
         (subdir (my/manifolding-atlas-prompt-subdir))
         (default-props (my/manifolding-atlas--all-warning-defaults 'file))
         (note (manifolding-atlas-create title fname
                           :properties default-props))
         (file-path (manifolding-atlas-note-path note)))
    (let* ((alias (my/manifolding-atlas-prompt-aliases))
           (tags (my/manifolding-atlas-org-prompt--ask-tags nil)))
      (require 'org-capture)
      (let ((org-capture-templates
             `(("n" "New Note" plain (file ,file-path)
                ,(concat "* TODO"
                         (if tags (concat " :" (mapconcat #'identity tags ":") ":") "")
                         "\n\n%?")
                :unnarrowed t
                :empty-lines 1))))
        (org-capture nil "n")
        (when alias
          (org-entry-put nil "ALIAS" (mapconcat #'identity alias ", ")))
        (let* ((template-names (append '("WARNING" "none")
                                       (my/manifolding-atlas-prompt-template--names)))
               (template (completing-read "TEMPLATE: " template-names nil t nil nil "WARNING"))
               (content (my/manifolding-atlas--get-template-content template)))
          (when content
            (goto-char (point-max))
            (insert content)))))
    note))

;;;###autoload

#+begin_src emacs-lisp
(cl-defun manifolding-atlas-find (&key other-window
                            filter-fn
                            candidates-fn
                            create-fn
                            require-match
                            (expand-aliases t))
  "Select and find a note.

If OTHER-WINDOW, visit the NOTE in another window.

CANDIDATES-FN is the function to query candidates for selection,
which takes as its argument a filtering function (see FILTER-FN).
Unless specified, `manifolding-atlas-find-default-candidates-source' is
used.

FILTER-FN is the function to apply on the candidates, which takes
as its argument a `manifolding-atlas-note'. Unless specified,
`manifolding-atlas-find-default-filter' is used.

CREATE-FN controls how a new note is created when user selects a
non-existent note (only possible when REQUIRE-MATCH is nil). Like
the CREATE-FN of `manifolding-atlas-insert', it is called with two arguments
- the typed title and capture properties (currently always nil).
It should return the created `manifolding-atlas-note' to visit, or nil to
skip visiting. Unless specified, `manifolding-atlas-find-default-create-fn'
is used.

When REQUIRE-MATCH is nil user may select a non-existent note,
which is then created via CREATE-FN. When non-nil, only existing
notes may be selected.

When EXPAND-ALIASES is non-nil (the default), each note with
aliases will appear multiple times in the completion list - once
for the original title and once for each alias."
  (interactive)
  (let* ((region-text
          (when (region-active-p)
            (org-link-display-format
             (buffer-substring-no-properties
              (set-marker
               (make-marker) (region-beginning))
              (set-marker
               (make-marker) (region-end))))))
         (note (manifolding-atlas-select-from
                "Note"
                (funcall
                 (or
                  candidates-fn
                  manifolding-atlas-find-default-candidates-source)
                 (or
                  filter-fn
                  manifolding-atlas-find-default-filter))
                :require-match require-match
                :initial-prompt region-text
                :expand-aliases expand-aliases)))
    (if (manifolding-atlas-note-id note)
        ;; Existing note - visit it
        (manifolding-atlas-visit note other-window)
      ;; New note - create it
      (when (not require-match)
        (let ((new-note (funcall (or create-fn
                                     manifolding-atlas-find-default-create-fn)
                                 (manifolding-atlas-note-title note)
                                 nil)))
          (when new-note
            (manifolding-atlas-visit new-note other-window)))))))

;;;###autoload

(defun manifolding-atlas-find-backlink ()
  "Select and find a note linked to current note.

Point lands on the first link pointing back to the current note,
so you see the mention itself instead of the beginning of the
selected note. When the link cannot be found in the buffer (e.g.
the file changed since the last sync), point stays at the note."
  (interactive)
  (let* ((id (or (org-entry-get nil "ID" t)
                 (user-error "Current location has no ID property")))
         (_ (unless (manifolding-atlas-db-get-by-id id)
              (user-error
               "%s is not a known note" id)))
         (backlinks (manifolding-atlas-db-query-by-links-some
                     (list (cons "id" id)))))
    (unless backlinks
      (user-error "There are no backlinks to the current note"))
    (let ((note (manifolding-atlas-select-from "Note" backlinks
                                    :require-match t
                                    :expand-aliases t)))
      (when (manifolding-atlas-note-id note)
        (manifolding-atlas-visit note)
        ;; Land on the link itself rather than the beginning of the note
        (when (re-search-forward
               (format "\\[\\[id:%s[]\\[]" (regexp-quote id))
               nil t)
          (goto-char (match-beginning 0))
          (manifolding-atlas--show-context))))))



(defun manifolding-atlas--show-context ()
  "Reveal the org context around point."
  (if (fboundp 'org-fold-show-context)
      (org-fold-show-context)
    ;; Fallback for Org < 9.6; the function is obsolete there but
    ;; still the correct entry point, so silence the warning.
    (with-suppressed-warnings ((obsolete org-show-context))
      (org-show-context))))

;;;###autoload

(defun manifolding-atlas-visit (note-or-id &optional other-window)
  "Visit NOTE-OR-ID.

If OTHER-WINDOW, visit the NOTE in another window."
  (let* ((note (if (manifolding-atlas-note-p note-or-id)
                   note-or-id
                 (manifolding-atlas-db-get-by-id note-or-id))))
    (unless note
      (user-error "Cannot find note with ID: %s"
                  (if (manifolding-atlas-note-p note-or-id)
                      (manifolding-atlas-note-id note-or-id)
                    note-or-id)))
    (let ((file (manifolding-atlas-note-path note))
          (id (manifolding-atlas-note-id note)))
      ;; Visit the file
      (if (or current-prefix-arg other-window)
          (find-file-other-window file)
        (find-file file))
      ;; Go to the note position
      (if (= (manifolding-atlas-note-level note) 0)
          ;; File-level note: go to beginning
          (goto-char (point-min))
        ;; Heading-level note: search for the ID property
        (goto-char (point-min))
        (unless (re-search-forward
                 (format "^[ \t]*:ID:[ \t]+%s[ \t]*$" (regexp-quote id))
                 nil t)
          (user-error "Could not find heading with ID: %s" id))
        ;; Move to the heading
        (org-back-to-heading t))
      (manifolding-atlas--show-context))))



(defvar manifolding-atlas-insert-default-filter nil
  "Default filter to use in `manifolding-atlas-insert'.")

(defvar manifolding-atlas-insert-default-candidates-source #'manifolding-atlas-db-query
  "Default source to get the list of candidates in `manifolding-atlas-insert'.

Must be a function that accepts one argument - optional note
filter function.")

(defvar manifolding-atlas-insert-default-create-fn nil
  "Default function to create a note in `manifolding-atlas-insert'.

When non-nil, used as the CREATE-FN of `manifolding-atlas-insert' for a note
that does not exist yet (see its CREATE-FN argument): it is called
with the typed title and capture properties and is responsible for
both creating the note and inserting the link. When nil, the
built-in behavior is used (create via `manifolding-atlas-create' and insert
an id: link).

This mirrors `manifolding-atlas-find-default-create-fn' for \"capture on
empty\" workflows. Note that, unlike the `manifolding-atlas-find' hook, this
function must perform the link insertion itself, since inserting a
link is what `manifolding-atlas-insert' does with a new note.")

(defvar manifolding-atlas-insert-handle-functions nil
  "Abnormal hooks to run after `manifolding-atlas-note' is inserted.

Each function accepts a note that was inserted via
`manifolding-atlas-insert'.

The current point is the point of the new node. The hooks must
not move the point.")

;;;###autoload

#+begin_src emacs-lisp
(cl-defun manifolding-atlas-insert (&key filter-fn candidates-fn create-fn
                              (expand-aliases t))
  "Select a note and insert a link to it.

Allows capturing new notes. After link is inserted,
`manifolding-atlas-insert-handle-functions' are called with the inserted
note as the only argument regardless involvement of capture
process.

CANDIDATES-FN is the function to query candidates for selection,
which takes as its argument a filtering function (see FILTER-FN).
Unless specified, `manifolding-atlas-insert-default-candidates-source' is
used.

FILTER-FN is the function to apply on the candidates, which takes
as its argument a `manifolding-atlas-note'. Unless specified,
`manifolding-atlas-insert-default-filter' is used.

CREATE-FN allows to control how a new note is created when user picks a
non-existent note. This function is called with two arguments - title
and capture properties. When CREATE-FN is nil,
`manifolding-atlas-insert-default-create-fn' is used; when that is also nil, the
default implementation is used.

When EXPAND-ALIASES is non-nil (the default), each note with
aliases will appear multiple times in the completion list - once
for the original title and once for each alias."
  (interactive)
  (unwind-protect
      (atomic-change-group
        (let* (region-text
               beg end
               (_ (when (region-active-p)
                    (setq
                     beg (set-marker
                          (make-marker) (region-beginning))
                     end (set-marker
                          (make-marker) (region-end))
                     region-text
                     (org-link-display-format
                      (buffer-substring-no-properties
                       beg end)))))
               (notes (funcall (or candidates-fn
                                   manifolding-atlas-insert-default-candidates-source)
                               (or filter-fn manifolding-atlas-insert-default-filter)))
               (note (manifolding-atlas-select-from "Note" notes
                                         :initial-prompt region-text
                                         :expand-aliases expand-aliases))
               (description (or region-text
                                (manifolding-atlas-note-title note))))
          (if (manifolding-atlas-note-id note)
              ;; Existing note - insert link immediately
              (progn
                (when region-text
                  (delete-region beg end)
                  (set-marker beg nil)
                  (set-marker end nil))
                (insert (org-link-make-string
                         (concat "id:" (manifolding-atlas-note-id note))
                         description))
                (run-hook-with-args
                 'manifolding-atlas-insert-handle-functions
                 note))
            ;; New note - create it then insert link
            (let ((cfn (or create-fn manifolding-atlas-insert-default-create-fn)))
              (if cfn
                  (funcall cfn (manifolding-atlas-note-title note) nil)
                ;; Create the note programmatically
                (let ((new-note (manifolding-atlas-create (manifolding-atlas-note-title note))))
                  (when region-text
                    (delete-region beg end)
                    (set-marker beg nil)
                    (set-marker end nil))
                  (insert (org-link-make-string
                           (concat "id:" (manifolding-atlas-note-id new-note))
                           description))
                  (run-hook-with-args
                   'manifolding-atlas-insert-handle-functions
                   new-note)))))))
    (deactivate-mark)))



(defun manifolding-atlas--format-heading-content (level id title &optional tags properties body)
  "Format a heading-level note content.

LEVEL is the heading depth (number of stars).
ID and TITLE are required.
TAGS is a list of tag strings (inserted as headline tags).
PROPERTIES is an alist of (key . value) for the property drawer.
BODY is optional body text after the property drawer."
  (string-join
   (append
    ;; Heading line with optional tags
    (list (concat (make-string level ?*)
                  " "
                  title
                  (when tags
                    (concat " :" (string-join tags ":") ":"))))
    ;; Property drawer
    (list ":PROPERTIES:"
          (format org-property-format ":ID:" id))
    (mapcar
     (lambda (prop)
       (format org-property-format
               (concat ":" (car prop) ":")
               (cdr prop)))
     properties)
    (list ":END:")
    ;; Body
    (when body (list body)))
   "\n"))

(defun manifolding-atlas--insert-heading-content (content blank-before)
  "Insert heading CONTENT at point with normalized blank lines.

CONTENT is heading text with no leading or trailing blank lines.
Any whitespace already surrounding point is removed first so the
result is deterministic.  When there is preceding content, CONTENT
starts on its own line, preceded by exactly one blank line when
BLANK-BEFORE is non-nil and none otherwise.  CONTENT is followed by
a single newline, which also guarantees a single trailing newline
when inserting at the end of the buffer."
  (skip-chars-backward " \t\n")
  (let ((preceding (not (bobp)))
        (following (save-excursion
                     (skip-chars-forward " \t\n")
                     (point))))
    (delete-region (point) following)
    (when preceding
      (insert "\n")
      (when blank-before (insert "\n")))
    (insert content "\n")))

;;;###autoload

#+begin_src emacs-lisp
(cl-defun manifolding-atlas-create (title
                         &optional file-name
                         &key
                         id
                         head
                         meta
                         body
                         context
                         properties
                         tags
                         parent
                         (after 'last))
  "Create a new note with TITLE programmatically.

This function is designed for programmatic note creation with
immediate finalization. For interactive note capture with user
editing, use `org-capture' with manifolding-atlas-compatible templates.

FILE-NAME is optional. When nil, uses `:file-name' from
`manifolding-atlas-create-default-template' to generate the file name.
Ignored when PARENT is provided (file is determined by parent).

Defaults from `manifolding-atlas-create-default-function' and
`manifolding-atlas-create-default-template' are applied only when creating a
file-level note (PARENT is nil).  When PARENT is provided no
defaults are consulted; the heading is built solely from the
arguments passed here.

Returns the created `manifolding-atlas-note' object.

ID is automatically generated unless explicitly passed.

When PARENT is nil, creates a file-level note:

  :PROPERTIES:
  :ID: ID
  PROPERTIES if present
  :END:
  #+title: TITLE
  #+filetags: TAGS if present
  HEAD if present

  META if present

  BODY if present

When PARENT is a `manifolding-atlas-note', creates a heading-level note
inside the parent's file at level (parent-level + 1):

  * TITLE :tags:
  :PROPERTIES:
  :ID: ID
  PROPERTIES if present
  :END:
  BODY if present

AFTER controls insertion position among siblings (only when
PARENT is provided):
  \\='last (default) - append as last child
  nil - insert as first child
  string (note ID) - insert after the child with that ID

Optional parameters:

- PROPERTIES: Alist of (key_str . val_str) for property drawer
- META: Alist of (key . value) or (key . (list of values))
- TAGS: List of tag strings
- BODY: Note body content (supports template expansion)
- HEAD: Additional header content (supports template expansion)
- CONTEXT: Plist of template variables (e.g., :url \"...\")

Template expansion is supported in FILE-NAME, HEAD, BODY, TAGS,
PROPERTIES values, and META values:
  ${var}     - Variable substitution (title, slug, timestamp, id, custom)
  %(elisp)   - Elisp evaluation (e.g., %(user-full-name))
  %<format>  - Timestamp formatting (e.g., %<[%Y-%m-%d]>)

Note: Does not support %a or %i from org-capture."
  (let* ((id (or id (org-id-new)))
         (context (or context nil)))
    (if parent
        ;; Heading-level note creation
        (manifolding-atlas--create-heading title id parent after
                               body tags properties context)
      ;; File-level note creation (original behavior)
      (manifolding-atlas--create-file title file-name id head meta body
                           tags properties context))))

(defvar-local manifolding-atlas--title-before-save nil
  "Title of note before save, for change detection.")

(defvar-local manifolding-atlas--note-id-before-save nil
  "ID of note before save, for change detection.")

(defun manifolding-atlas--capture-before-save ()
  "Capture note ID and title before save for change detection.
The old title is read from the database, not the buffer."
  (when (derived-mode-p 'org-mode)
    (setq manifolding-atlas--note-id-before-save (org-entry-get nil "ID"))
    (setq manifolding-atlas--title-before-save
          (when manifolding-atlas--note-id-before-save
            (caar (emacsql (manifolding-atlas-db)
                           [:select title :from notes :where (= id $s1)]
                           manifolding-atlas--note-id-before-save))))))

(defun manifolding-atlas--notify-title-change ()
  "After save, check if title changed and notify user."
  (when (and manifolding-atlas--note-id-before-save
             manifolding-atlas--title-before-save
             (derived-mode-p 'org-mode))
    (let ((new-title (manifolding-atlas-buffer-title-get)))
      (when (and new-title
                 (not (string= new-title manifolding-atlas--title-before-save)))
        (message
         (concat "Title changed from \"%s\" to \"%s\". "
                 "Run M-x manifolding-atlas-propagate-title-change to update.")
         manifolding-atlas--title-before-save new-title)))))

;;;###autoload
(define-minor-mode manifolding-atlas-title-change-detection-mode
  "Minor mode to detect title changes and notify user.

When enabled, this mode tracks the note's title before each save.
After saving, if the title has changed, it notifies the user and
suggests running `manifolding-atlas-propagate-title-change' to update incoming
link descriptions."
  :lighter " VulpTD"
  :group 'manifolding-atlas
  (if manifolding-atlas-title-change-detection-mode
      (progn
        (add-hook 'before-save-hook #'manifolding-atlas--capture-before-save nil t)
        (add-hook 'after-save-hook #'manifolding-atlas--notify-title-change nil t))
    (remove-hook 'before-save-hook #'manifolding-atlas--capture-before-save t)
    (remove-hook 'after-save-hook #'manifolding-atlas--notify-title-change t)))

;;; Title Propagation Command

;;;###autoload

#+begin_src emacs-lisp
(cl-defun manifolding-atlas-propagate-title-change (&optional note-or-id)
  "Propagate title change for NOTE-OR-ID to filename and links.

With prefix arg (\\[universal-argument]), preview changes without
applying (dry-run).

When called interactively:
- Determines the note from current buffer or prompts user
- Prompts for old title if not recently detected
- Offers to rename the file based on new title
- Updates exact-match link descriptions to new title
- Shows partial matches for manual review

Interactive flow:
1. Prompt for file rename (y/n)
2. For exact matches: [!] Update all, [r] Review, [s] Skip, [q] Quit
3. Partial matches shown with option to open files"
  (interactive)
  (let* ((dry-run current-prefix-arg)
         ;; Determine the note
         (note (cond
                ((manifolding-atlas-note-p note-or-id) note-or-id)
                ((stringp note-or-id) (manifolding-atlas-db-get-by-id note-or-id))
                (t (when-let* ((id (org-entry-get nil "ID")))
                     (manifolding-atlas-db-get-by-id id)))))
         (note (or note
                   (manifolding-atlas-select "Note to propagate")))
         (note-id (manifolding-atlas-note-id note))
         (new-title (manifolding-atlas-note-title note))
         ;; Get old title - from detection or prompt
         (old-title
          (or manifolding-atlas--title-before-save
              (read-string (format "Old title (new: \"%s\"): " new-title))))
         ;; Get incoming links
         (links (manifolding-atlas--get-incoming-links-with-descriptions note-id))
         (categorized (manifolding-atlas--categorize-links links old-title))
         (exact-links (plist-get categorized :exact))
         (partial-links (plist-get categorized :partial))
         (exact-count (length exact-links))
         (partial-count (length partial-links)))

    ;; Check if title actually changed
    (when (string= old-title new-title)
      (user-error "Title has not changed (\"%s\")" new-title))

    ;; Dry-run: just show summary
    (when dry-run
      (with-output-to-temp-buffer "*manifolding-atlas-propagate-preview*"
        (princ (format "Title propagation preview for: %s\n" note-id))
        (princ (format "Old title: %s\n" old-title))
        (princ (format "New title: %s\n\n" new-title))
        (princ (format "File rename: %s → %s\n\n"
                       (file-name-nondirectory (manifolding-atlas-note-path note))
                       (concat (manifolding-atlas-title-to-slug new-title) ".org")))
        (princ (format "Exact matches (%d):\n" exact-count))
        (dolist (link exact-links)
          (princ (format "  %s at pos %d: \"%s\"\n"
                         (file-name-nondirectory (plist-get link :source-path))
                         (plist-get link :pos)
                         (plist-get link :description))))
        (princ (format "\nPartial matches (%d):\n" partial-count))
        (dolist (link partial-links)
          (princ (format "  %s at pos %d: \"%s\"\n"
                         (file-name-nondirectory (plist-get link :source-path))
                         (plist-get link :pos)
                         (plist-get link :description)))))
      (message "Dry-run complete. See *manifolding-atlas-propagate-preview* buffer.")
      (cl-return-from manifolding-atlas-propagate-title-change))

    ;; Offer file rename for file-level notes
    (when (and (= (manifolding-atlas-note-level note) 0)
               (y-or-n-p
                (format "Rename file \"%s\" → \"%s\"? "
                        (file-name-nondirectory (manifolding-atlas-note-path note))
                        (concat (manifolding-atlas-title-to-slug new-title) ".org"))))
      (condition-case err
          (manifolding-atlas-rename-file note new-title)
        (error (message "File rename failed: %s" (error-message-string err)))))

    ;; Handle exact matches
    (when (> exact-count 0)
      (message "Found %d exact match%s, %d partial match%s"
               exact-count (if (= exact-count 1) "" "es")
               partial-count (if (= partial-count 1) "" "es"))
      (let ((action
             (read-char-choice
              (format "Exact (%d): [!] All  [r] Review  [s] Skip  [q] Quit: "
                      exact-count)
              '(?! ?r ?s ?q))))
        (pcase action
          (?! ;; Update all exact matches
           (dolist (link exact-links)
             (manifolding-atlas--update-link-description
              (plist-get link :source-path)
              (plist-get link :pos)
              new-title)
             (when-let* ((buf (get-file-buffer (plist-get link :source-path))))
               (with-current-buffer buf
                 (save-buffer))))
           (message "Updated %d link%s"
                    exact-count (if (= exact-count 1) "" "s")))
          (?r ;; Review individually
           (let ((updated 0))
             (dolist (link exact-links)
               (let ((path (plist-get link :source-path))
                     (pos (plist-get link :pos))
                     (desc (plist-get link :description)))
                 (when (y-or-n-p (format "Update \"%s\" in %s? "
                                         desc (file-name-nondirectory path)))
                   (manifolding-atlas--update-link-description path pos new-title)
                   (when-let* ((buf (get-file-buffer path)))
                     (with-current-buffer buf
                       (save-buffer)))
                   (cl-incf updated))))
             (message "Updated %d of %d link%s"
                      updated exact-count (if (= exact-count 1) "" "s"))))
          (?s ;; Skip exact matches
           (message "Skipped exact matches"))
          (?q ;; Quit
           (user-error "Aborted")))))

    ;; Handle partial matches
    (when (> partial-count 0)
      (when (y-or-n-p
             (format "Open %d file%s with partial matches for editing? "
                     partial-count (if (= partial-count 1) "" "s")))
        (let ((files (delete-dups
                      (mapcar (lambda (l) (plist-get l :source-path))
                              partial-links))))
          (dolist (file files)
            (find-file-other-window file)))))

    ;; Clear detection state
    (setq manifolding-atlas--title-before-save nil)

    (message "Title propagation complete.")))

;;;###autoload

(defun manifolding-atlas-rename-file (note-or-id new-title)
  "Rename NOTE-OR-ID's file based on NEW-TITLE slug.
Updates the file on disk and database.

The new filename is generated as NEW-TITLE converted to slug with
.org extension, placed in the same directory as the original file.

Returns the new file path.

Signals an error if:
- The note cannot be found
- The target file already exists
- The note is a heading-level note (level > 0)"
  (let* ((note (if (manifolding-atlas-note-p note-or-id)
                   note-or-id
                 (manifolding-atlas-db-get-by-id note-or-id)))
         (old-path (when note (manifolding-atlas-note-path note)))
         (dir (when old-path (file-name-directory old-path)))
         (new-filename (concat (manifolding-atlas-title-to-slug new-title) ".org"))
         (new-path (when dir (expand-file-name new-filename dir))))
    (unless note
      (error "manifolding-atlas-rename-file: Cannot find note with ID: %s"
             (if (manifolding-atlas-note-p note-or-id)
                 (manifolding-atlas-note-id note-or-id)
               note-or-id)))
    (when (> (manifolding-atlas-note-level note) 0)
      (error "manifolding-atlas-rename-file: Cannot rename file for heading-level note"))
    (when (file-exists-p new-path)
      (error "manifolding-atlas-rename-file: Target file already exists: %s" new-path))
    ;; Kill buffer if file is open
    (let ((buf (get-file-buffer old-path)))
      (when buf
        (with-current-buffer buf
          (save-buffer))
        (kill-buffer buf)))
    ;; Rename file on disk
    (rename-file old-path new-path)
    ;; Update org-id location
    (org-id-add-location (manifolding-atlas-note-id note) new-path)
    ;; Delete old file from database and add new one
    (manifolding-atlas-db--delete-file-notes old-path)
    (manifolding-atlas-db-update-file new-path)
    new-path))



;;; Schema authoring

(defun manifolding-atlas--schema-buffer-note (&optional schema)
  "Build a synthetic `manifolding-atlas-note' from the note at point.

The note carries the title and tags of the note at point - the heading
when point is inside one, otherwise the file.  When SCHEMA is given, it
also carries the current values of that schema's field keys within the
same scope, so predicates, conditional :required / :one-of rules and the
missing-field computation see in-buffer content while authoring."
  (make-manifolding-atlas-note
   :title (if (org-before-first-heading-p)
              (manifolding-atlas-buffer-title-get)
            (substring-no-properties (org-get-heading t t t t)))
   :tags (manifolding-atlas-buffer-tags-get)
   :meta (when schema
           (delq nil
                 (mapcar
                  (lambda (field)
                    (let* ((key (plist-get field :key))
                           (vals (manifolding-atlas-buffer-meta-get-list key 'string 'heading)))
                      (when vals (cons key vals))))
                  (manifolding-atlas-blueprint-fields (manifolding-atlas-blueprint--resolve schema)))))))

(defun manifolding-atlas--schema-read-schema (note)
  "Choose a schema to author NOTE against, prompting when ambiguous.

Returns a schema name symbol.  Uses the schema applicable to NOTE when
exactly one matches, prompts among the matches when several do, and
prompts over all registered schemas when none match."
  (let ((applicable (manifolding-atlas-blueprint-applicable note)))
    (cond
     ((= (length applicable) 1) (car applicable))
     (applicable
      (intern (completing-read "Schema: " (mapcar #'symbol-name applicable) nil t)))
     (t
      (let ((all (manifolding-atlas-blueprint-list)))
        (unless all (user-error "No schemas are registered"))
        (intern (completing-read "Schema: " (mapcar #'symbol-name all) nil t)))))))

(defun manifolding-atlas--schema-prompt-field (field note required)
  "Prompt for a value for FIELD.

NOTE gives context and REQUIRED is non-nil when the field is required.
Honors :type (note selection for `note' / `link'), :one-of (completion),
:one-of with :multiple (multi-selection), and :target-tags (restricting
note selection to notes carrying every listed tag).  Quitting a note
prompt skips that field.  Returns the entered value, a list of values,
or an empty value when skipped."
  (let* ((type (or (plist-get field :type) 'string))
         (one-of (manifolding-atlas-blueprint--call-or-value (plist-get field :one-of) note))
         (multiple (plist-get field :multiple))
         (target-tags (plist-get field :target-tags))
         (prompt (format "%s%s: " (plist-get field :key)
                         (if required " (required)" "")))
         (candidates (lambda () (mapcar (lambda (v) (format "%s" v)) one-of))))
    (cond
     ((memq type '(note link))
      (condition-case nil
          (if target-tags
              (manifolding-atlas-select prompt :require-match t
                             :filter-fn
                             (lambda (n)
                               (cl-every (lambda (tag)
                                           (member tag (manifolding-atlas-note-tags n)))
                                         target-tags)))
            (manifolding-atlas-select prompt :require-match t))
        (quit nil)))
     ((and one-of multiple)
      (completing-read-multiple prompt (funcall candidates)))
     (one-of
      (completing-read prompt (funcall candidates)))
     (t (read-string prompt)))))

(defun manifolding-atlas--schema-prompt-fields (fields note)
  "Prompt for each field in FIELDS, returning a (KEY . VALUE) alist.

NOTE supplies context for conditional :required and :one-of.  An empty
answer drops an optional field but keeps a required one as an empty
placeholder, so the author is still reminded of it."
  (let (values)
    (dolist (field fields)
      (let* ((key (plist-get field :key))
             (required (manifolding-atlas-blueprint--call-or-value
                        (plist-get field :required) note))
             (value (manifolding-atlas--schema-prompt-field field note required))
             ;; a multi-value answer may contain blank entries (e.g. an
             ;; empty `completing-read-multiple'); drop them so an empty
             ;; optional field is not written as a stray placeholder
             (value (if (listp value) (remove "" value) value)))
        (cond
         ((and value (not (equal value "")))
          (push (cons key value) values))
         (required (push (cons key "") values)))))
    (nreverse values)))

(defun manifolding-atlas--schema-insert-field-values (fields values &optional bound)
  "Write FIELDS into the current buffer, taking values from VALUES.

FIELDS is an ordered list of field specs.  VALUES is an alist mapping a
field :key to a value or list of values; a field absent from VALUES is
written as an empty placeholder.  Fields are appended in order, so a
`note' value (or a bare id) becomes a proper link via
`manifolding-atlas-buffer-meta-format'.  BOUND limits the scope as in
`manifolding-atlas-buffer-meta-set'."
  (dolist (field fields)
    (let* ((key (plist-get field :key))
           (cell (assoc key values)))
      (manifolding-atlas-buffer-meta-set key (if cell (cdr cell) "") 'append bound))))

;;;###autoload

(defun manifolding-atlas-blueprint-insert-fields (&optional schema-or-name skeleton)
  "Insert an applicable schema's fields into the current buffer.

The schema is taken from SCHEMA-OR-NAME when given, otherwise chosen
from the schemas applicable to the current buffer (prompting when
several apply, or over all registered schemas when none do).

For each field the note does not already carry, prompt for a value -
offering :one-of values as completion and selecting a note for `note'
fields - and insert it; required fields are handled first.  With a
prefix argument (SKELETON non-nil), skip prompting and insert empty
placeholders for every missing field instead.

The fields are inserted into the note at point: the heading's subtree
when point is inside one, otherwise the file-level metadata."
  (interactive (list nil current-prefix-arg))
  (let* ((schema (or schema-or-name
                     (manifolding-atlas--schema-read-schema (manifolding-atlas--schema-buffer-note))))
         (note (manifolding-atlas--schema-buffer-note schema))
         (fields (manifolding-atlas-blueprint-missing-fields note schema)))
    (if skeleton
        (manifolding-atlas--schema-insert-field-values fields nil 'heading)
      (let ((values (manifolding-atlas--schema-prompt-fields fields note)))
        (manifolding-atlas--schema-insert-field-values
         (cl-remove-if-not (lambda (f) (assoc (plist-get f :key) values)) fields)
         values 'heading)))))

;;;###autoload

(defun manifolding-atlas-blueprint-fix-violation (violation &optional bound)
  "Fix VIOLATION in the current buffer by prompting for a corrected value.

Resolves the violated field from VIOLATION's schema and prompts for a
value the way `manifolding-atlas-blueprint-insert-fields' does - offering :one-of
values as completion, selecting a note for `note' fields, restricting to
:target-tags - then writes it, replacing the offending value or
inserting the field when it was missing.  Returns the value written, or
nil when the prompt is skipped.

BOUND limits the scope as in `manifolding-atlas-buffer-meta-set' and defaults to
\\='heading, so the fix is written into the note at point - the heading's
subtree when point is inside one, otherwise the file-level metadata.
This matches how the violating note is read, so a heading-level fix does
not rewrite an unrelated file-level value; pass \\='buffer to force
file-level scope.

This is the headless building block UIs use to offer one-key fixes for a
`manifolding-atlas-blueprint-validate' violation."
  (let* ((schema (manifolding-atlas-blueprint--resolve (manifolding-atlas-violation-schema violation)))
         (field (cl-find (manifolding-atlas-violation-field violation)
                         (manifolding-atlas-blueprint-fields schema)
                         :key (lambda (f) (plist-get f :key))
                         :test #'equal))
         (note (manifolding-atlas--schema-buffer-note schema))
         (required (manifolding-atlas-blueprint--call-or-value (plist-get field :required) note))
         (value (manifolding-atlas--schema-prompt-field field note required))
         (value (if (listp value) (remove "" value) value)))
    (when (and field value (not (equal value "")))
      (manifolding-atlas-buffer-meta-set (plist-get field :key) value 'append (or bound 'heading))
      value)))

;;; capture.el --- Key-selection region & heading capture for manifolding-atlas v2 -*- lexical-binding: t; -*-

(require 'org)

(defun my/manifolding-atlas--create-file-wrapper (title file-name tags properties body)
  "Wrapper for `manifolding-atlas-create' with simplified signature."
  (manifolding-atlas-create title file-name
                            :body body
                            :properties properties
                            :tags tags))

(defun my/manifolding-atlas--heading-subtree-text ()
  "Return (title . body-text) for the org heading at point.
Title is the raw heading text; body is everything under it,
excluding the property drawer."
  (save-excursion
    (org-back-to-heading t)
    (let* ((title (org-get-heading t t t t))
           (beg   (progn (forward-line 1)
                         (when (looking-at ":PROPERTIES:")
                           (re-search-forward "^:END:" nil t)
                           (forward-line 1))
                         (point)))
           (end   (progn (org-end-of-subtree t t) (point)))
           (body  (buffer-substring-no-properties beg end)))
      (cons title body))))

(defun my/manifolding-atlas--delete-heading ()
  "Delete the org heading at point and its entire subtree."
  (org-back-to-heading t)
  (let ((beg (point))
        (end (progn (org-end-of-subtree t t) (point))))
    (delete-region beg end)))

(defun my/manifolding-atlas--replace-heading-with-link (id title)
  "Delete the org heading at point; insert an org-id link to ID with TITLE."
  (org-back-to-heading t)
  (let ((beg (point))
        (end (progn (org-end-of-subtree t t) (point))))
    (delete-region beg end)
    (insert (org-link-make-string (concat "id:" id) title) "\n")))

(defun my/manifolding-atlas--transplant-body (note body)
  "Write BODY as NOTE's content, replacing any default."
  (manifolding-atlas-visit note)
  (goto-char (point-min))
  (when (looking-at ":PROPERTIES:")
    (re-search-forward "^:END:" nil t)
    (forward-line 1))
  (end-of-line)
  (forward-line 1)
  (delete-region (point) (point-max))
  (insert body)
  (save-buffer))

(defun my/manifolding-atlas--finish-heading-extraction (note title)
  "Ask whether to leave a backlink to NOTE or delete the heading at point."
  (org-back-to-heading t)
  (if (string= (read-answer "Insert backlink? "
                  '(("yes" ?y "insert backlink")
                    ("no"  ?n "delete heading without link")))
               "yes")
      (let* ((desc (read-string "Description (blank = title): "))
             (link-desc (unless (string-empty-p desc) desc)))
        (my/manifolding-atlas--replace-heading-with-link
         (manifolding-atlas-note-id note) (or link-desc title)))
    (my/manifolding-atlas--delete-heading)))

(defun my/manifolding-atlas-heading-to-note ()
  "Extract the org heading at point into its own manifolding-atlas note file.
Uses `manifolding-atlas-create' for all standard prompts (subdir, file name,
aliases, tags, properties, todo, priority, schedule, deadline),
then fills the body with the extracted heading content.
Records the original heading as 'source'.
Prompts for backlink — yes inserts a link, no deletes the heading."
  (interactive)
  (unless (org-at-heading-p)
    (org-back-to-heading t))
  (let* ((heading-id (org-id-get))
         (pair       (my/manifolding-atlas--heading-subtree-text))
         (title      (read-string "Note title: " (car pair)))
         (body       (cdr pair))
         (note       (manifolding-atlas-create title nil))
         (original-buffer (current-buffer)))
    ;; Record source relationship pointing back to original heading
    (when (and note heading-id)
      (my/manifolding-atlas--property-put note "SOURCE" heading-id))
    ;; Replace the default body with the extracted heading content
    (my/manifolding-atlas--transplant-body note body)
    ;; Backlink or delete — work in the original buffer
    (with-current-buffer original-buffer
      (save-excursion
        (my/manifolding-atlas--finish-heading-extraction note title)))
    (message "Extracted → %s" (manifolding-atlas-note-title note))))

(require 'cl-lib)
(setq max-lisp-eval-depth (max max-lisp-eval-depth 6000)
      max-specpdl-size (max max-specpdl-size 6000))

(defvar my/manifolding-atlas-org-prompt--declarative
  (make-hash-table :test #'eq)
  "Registry keys registered from declarative org outlines.")

(defvar my/manifolding-atlas-org-prompt--specs
  (make-hash-table :test #'eq)
  "Full spec plists per registry key.")

(defun my/manifolding-atlas-org-prompt--declarative-p (key)
  "Return non-nil when KEY was registered by the declarative engine."
  (and (hash-table-p my/manifolding-atlas-org-prompt--declarative)
       (gethash key my/manifolding-atlas-org-prompt--declarative)))

(defvar my/manifolding-atlas-org-prompt--deferred nil)

(defconst my/manifolding-atlas-prompt-warning "WARNING"
  "Sentinel option meaning \"prompt skipped\".")

(defun my/manifolding-atlas-org-prompt--normalize-choice (val)
  (cond ((null val) val)
        ((string-equal val "⚠ WARNING") "WARNING")
        ((string-equal val "⚠ tag-warning") "tag-warning")
        (t val)))

(defvar my/manifolding-atlas--quiet nil)

(defun my/manifolding-atlas--hush-message (orig fmt &rest args)
  (unless my/manifolding-atlas--quiet
    (apply orig fmt args)))

(advice-add 'message :around #'my/manifolding-atlas--hush-message)

(defconst my/manifolding-atlas-prompt-template--none "none")

(defvar my/manifolding-atlas-prompt-template--deferred nil
  "When non-nil, defer to the file-level preview chooser.")

(defun my/manifolding-atlas-prompt-template--defer-around (orig &rest args)
  (let ((my/manifolding-atlas-prompt-template--deferred t))
    (apply orig args)))

(with-eval-after-load 'manifolding-atlas
  (dolist (fn '(my/manifolding-atlas-capture-new-file
                my/manifolding-atlas-capture-task-file))
    (advice-add fn :around
                #'my/manifolding-atlas-prompt-template--defer-around)))

(defun my/manifolding-atlas-prompt-template--names ()
  "Return available template names from templates/files."
  (condition-case nil
      (mapcar (lambda (f)
                (file-name-sans-extension (file-name-nondirectory f)))
              (directory-files (expand-file-name "files" (my/manifolding-atlas-template-files-dir))
                               t "\\.org\\'"))
    (error nil)))

(defun my/manifolding-atlas-prompt-template--choose ()
  "Ask for TEMPLATE. Returns \"WARNING\" if skipped, \"none\" for none."
  (if my/manifolding-atlas-prompt-template--deferred
      "WARNING"
    (completing-read "TEMPLATE: "
                     (append '("WARNING" "none")
                             (my/manifolding-atlas-prompt-template--names))
                     nil t nil nil "WARNING")))

(defun my/manifolding-atlas-prompt-template--apply (val note)
  "Post-apply: keep TEMPLATE_HASH in sync with VAL on NOTE."
  (when note
    (if (and val
             (not (member val (list "WARNING"
                                    my/manifolding-atlas-prompt-template--none))))
        (my/manifolding-atlas--property-put
         note "TEMPLATE_HASH"
         (or (my/manifolding-atlas--capture-file-hash val) "unknown"))
      (manifolding-atlas-visit note)
      (org-entry-delete nil "TEMPLATE_HASH")
      (save-buffer))))

(defun my/manifolding-atlas-org-prompt--parse-drawer ()
  "Read the :PROPERTIES: drawer following the current line.
Advances point past :END: and returns the drawer plist."
  (forward-line 1)
  (let ((plist nil))
    (when (looking-at "^[ \t]*:PROPERTIES:[ \t]*$")
      (forward-line 1)
      (while (not (or (eobp) (looking-at "^[ \t]*:END:[ \t]*$")))
        (when (looking-at "^[ \t]*:\\([A-Za-z-]+\\):[ \t]*\\(.*\\)$")
          (setq plist
                (plist-put plist
                           (intern
                            (concat ":"
                                    (downcase (match-string 1))))
                           (string-trim (match-string 2)))))
        (forward-line))
      (forward-line 1))
    plist))

(defun my/manifolding-atlas-org-prompt--parse-flush (key opts plist specs)
  "Push KEY's accumulated OPTIONS and PLIST onto SPECS."
  (if key
      (cons (list key (nreverse opts) plist) specs)
    specs))

(defun my/manifolding-atlas-org-prompt--parse (file)
  "Return specs (KEY OPTIONS PLIST) declared in FILE, or nil."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (unless (re-search-forward "begin_src" nil t)
      (goto-char (point-min))
      (let ((specs nil) key opts plist)
        (while (not (eobp))
          (cond
           ((looking-at "^\\* \\([A-Z][A-Z0-9_]*\\)[ \t]*$")
            (setq specs (my/manifolding-atlas-org-prompt--parse-flush
                         key opts plist specs)
                  key (match-string 1) opts nil plist nil
                  plist (my/manifolding-atlas-org-prompt--parse-drawer)))
           ((and key (looking-at "^\\*\\*+ [. ]*\\(.*?\\)[ \t]*$"))
            (push (match-string 1) opts)
            (forward-line 1))
           ((looking-at "^\\* ")
            (setq specs (my/manifolding-atlas-org-prompt--parse-flush
                         key opts plist specs)
                  key nil opts nil plist nil)
            (forward-line 1))
           (t (forward-line 1))))
        (nreverse
         (my/manifolding-atlas-org-prompt--parse-flush
          key opts plist specs))))))

(defun my/manifolding-atlas-blueprint-dir ()
  "Return the blueprints directory."
  (expand-file-name "Manifolding-Emacs/modules/manifolding-atlas/blueprints/"
                    user-emacs-directory))

(defun my/manifolding-atlas-org-prompt--schema-files ()
  "Return all candidate org files under blueprints/."
  (directory-files-recursively
   (my/manifolding-atlas-blueprint-dir) "\\.org\\'"))

(defun my/manifolding-atlas-org-prompt--register-file (file failures)
  "Register every spec parsed from FILE.
Returns (COUNT . FAILURES) — prompts registered plus the possibly
extended failure list."
  (let ((count 0)
        (specs (condition-case err
                   (my/manifolding-atlas-org-prompt--parse file)
                 (error
                  (push (format "%s: parse failed (%s)"
                                (file-name-nondirectory file)
                                (error-message-string err))
                        failures)
                  nil))))
    (dolist (spec specs)
      (condition-case err
          (progn
            (apply #'my/manifolding-atlas-org-prompt--register file spec)
            (setq count (1+ count)))
        (error
         (push (format "%s: %s"
                       (file-name-nondirectory file)
                       (error-message-string err))
               failures))))
    (cons count failures)))

(defun my/manifolding-atlas-org-prompt--register-all ()
  "Register every declarative prompt found under blueprints/.
Idempotent: strips previously registered declarative specs first, so
repeated reloads/boot timers never duplicate registry entries.
Per-file/per-spec failures are reported individually instead of
aborting the whole batch.  Returns number of prompts registered."
  (let ((count 0) (failures nil))
    ;; Drop stale declarative specs from earlier registrations.
    (setq my/manifolding-atlas-prompt-registry
          (cl-remove-if
           (lambda (spec)
             (my/manifolding-atlas-org-prompt--declarative-p
              (plist-get spec :key)))
           my/manifolding-atlas-prompt-registry))
    (dolist (file (my/manifolding-atlas-org-prompt--schema-files))
      (let ((result (my/manifolding-atlas-org-prompt--register-file
                     file failures)))
        (setq count (+ count (car result))
              failures (cdr result))))
    (when failures
      (lwarn 'manifolding-atlas-org-prompts :warning
             "declarative prompt failures:\n%s"
             (string-join (nreverse failures) "\n")))
    count))

(defun my/manifolding-atlas-org-prompt--run (key-sym &optional default)
  "Invoke declarative prompt KEY-SYM using its stored spec.
Direct single-shot callers only; capture flows defer to async sessions."
  (let ((spec (gethash key-sym
                       my/manifolding-atlas-org-prompt--specs)))
    (if (not spec)
        (user-error "No declarative spec for %s — reload org-prompts"
                    key-sym)
      (let* ((file (plist-get spec :file))
             (key (plist-get spec :key))
             (label (plist-get spec :label))
             (kind (plist-get spec :kind))
             (options (plist-get spec :options))
             (plist (plist-get spec :plist)))
        (my/manifolding-atlas-org-prompt--ask
         file key label kind options plist default)))))

(defun my/manifolding-atlas-org-prompt--read-current-fn (kind prop)
  "Return the read-current lambda for KIND reading PROP."
  (cond ((eq kind 'todo) `(lambda () (org-get-todo-state)))
        ((eq kind 'tags) `(lambda () (org-get-tags nil t)))
        (t `(lambda () (org-entry-get nil ,prop)))))

(defun my/manifolding-atlas-org-prompt--to-plist-fn (kind prop plist)
  "Return the to-plist lambda converting picks for KIND/PROP."
  `(lambda (val _ctx) (my/manifolding-atlas-org-prompt--fragment
                       ,prop ',kind ',plist val)))

(defun my/manifolding-atlas-org-prompt--register-defalias (key-sym)
  "Define my/manifolding-atlas-prompt-KEY-SYM as a spec-reading runner."
  (let ((fn (intern (concat "my/manifolding-atlas-prompt-"
                            (symbol-name key-sym)))))
    (when (and (fboundp fn)
               (not (get fn 'my/manifolding-atlas-declarative)))
      (lwarn 'manifolding-atlas-org-prompts :warning
             "declarative prompt %s shadows existing function %s"
             key-sym fn))
    (defalias fn
      `(lambda () (my/manifolding-atlas-org-prompt--run ',key-sym)))
    (put fn 'my/manifolding-atlas-declarative t)))

(defun my/manifolding-atlas-org-prompt--register-base-entry
    (key-sym label kind prop plist contexts)
  "Register KEY-SYM for CONTEXTS under the base registry key."
  (my/manifolding-atlas-register-prompt
   :key key-sym
   :name key-sym
   :label label
   :prompt-fn `(lambda () (my/manifolding-atlas-org-prompt--run ',key-sym))
   :contexts contexts
   :read-current-fn (my/manifolding-atlas-org-prompt--read-current-fn
                     kind prop)
   :merge-strategy (if (eq kind 'tags) 'merge 'replace)
   :to-plist (my/manifolding-atlas-org-prompt--to-plist-fn
              kind prop plist)))

(defun my/manifolding-atlas-org-prompt--register-task-entry
    (key-sym label kind prop plist task-default)
  "Register KEY-SYM's task twin defaulting to TASK-DEFAULT."
  (my/manifolding-atlas-register-prompt
   :key (intern (concat (symbol-name key-sym) "--task"))
   :name key-sym
   :label label
   :prompt-fn `(lambda ()
                (my/manifolding-atlas-org-prompt--run
                 ',key-sym ,task-default))
   :contexts '(task)
   :read-current-fn (my/manifolding-atlas-org-prompt--read-current-fn
                     kind prop)
   :merge-strategy (if (eq kind 'tags) 'merge 'replace)
   :to-plist (my/manifolding-atlas-org-prompt--to-plist-fn
              kind prop plist)))

(defun my/manifolding-atlas-org-prompt--register (file key options plist)
  "Register one declarative prompt from FILE: KEY with OPTIONS and PLIST."
  (let* ((key-sym (intern (downcase
                           (or (plist-get plist :id)
                               (replace-regexp-in-string "_" "-" key)))))
         (prop key)
         (kind (intern (downcase
                        (or (plist-get plist :kind) "property"))))
         (contexts (mapcar #'intern
                           (split-string
                            (or (plist-get plist :contexts)
                                "file heading"))))
         (label (or (plist-get plist :label) key))
         (task-default (plist-get plist :task-default)))
    (puthash key-sym t my/manifolding-atlas-org-prompt--declarative)
    (puthash key-sym
             (list :file file :key key :label label :kind kind
                   :options options :plist plist
                   :task-default task-default)
             my/manifolding-atlas-org-prompt--specs)
    (my/manifolding-atlas-org-prompt--register-defalias key-sym)
    (my/manifolding-atlas-org-prompt--register-base-entry
     key-sym label kind prop plist contexts)
    (when (and task-default (memq 'task contexts))
      (my/manifolding-atlas-org-prompt--register-task-entry
       key-sym label kind prop plist task-default))))

(defcustom my/manifolding-atlas-org-prompt-ui 'buffer
  "How declarative prompts ask for a value.
`buffer'     open the prompt's org file; navigate freely, RET on an
             option heading (level 2 or deeper — level-3+ are variants)
             selects it, m marks for multi-select, q cancels.
`minibuffer' classic completing-read over the flattened options."
  :type '(choice (const :tag "File buffer" buffer)
                 (const :tag "Minibuffer" minibuffer))
  :group 'manifolding-atlas)

(defvar my/manifolding-atlas-org-prompt--buffer-result nil)
(defvar my/manifolding-atlas-org-prompt--buffer-marks nil)
(defvar-local my/manifolding-atlas-org-prompt--applied nil
  "Value currently applied to the target note from this picker.")

(defun my/manifolding-atlas-org-prompt--buffer-refresh-marks ()
  (remove-overlays (point-min) (point-max) 'atlas-mark t)
  (dolist (title my/manifolding-atlas-org-prompt--buffer-marks)
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward
             (format "^\\*\\*+ %s[ \t]*$" (regexp-quote title)) nil t)
        (let ((ov (make-overlay (line-beginning-position)
                                (line-end-position))))
          (overlay-put ov 'atlas-mark t)
          (overlay-put ov 'face 'highlight))))))

(defun my/manifolding-atlas-org-prompt--accept-session ()
  "Session RET: record, close the picker, advance.
An accidental RET can never commit a wrong pick — advancing is
refused until m has applied something."
  (when (and (null my/manifolding-atlas-org-prompt--applied)
             (null my/manifolding-atlas-org-prompt--buffer-marks))
    (user-error "Nothing applied yet — press m on an option first"))
  (my/manifolding-atlas-org-prompt--session-record-answer)
  (my/manifolding-atlas-org-prompt--buffer-finish)
  (my/manifolding-atlas-org-prompt--session-next))

(defun my/manifolding-atlas-org-prompt--accept-standalone (title)
  "Standalone RET: store TITLE (or joined marks) and leave recursive-edit."
  (setq my/manifolding-atlas-org-prompt--buffer-result
        (if (and (eq my/manifolding-atlas-org-prompt--this-kind 'multi)
                 my/manifolding-atlas-org-prompt--buffer-marks)
            (string-join
             (mapcar #'my/manifolding-atlas-org-prompt--normalize-choice
                     (reverse my/manifolding-atlas-org-prompt--buffer-marks))
             " ")
          title))
  (my/manifolding-atlas-org-prompt--buffer-finish)
  (exit-recursive-edit))

(defun my/manifolding-atlas-org-prompt--buffer-accept ()
  "Advance to the next prompt (session) or accept the value.
In an async session RET only advances when something has been
applied with m — an accidental RET can never commit a wrong pick."
  (interactive)
  (if (not (and (org-at-heading-p) (>= (org-outline-level) 2)))
      (message "Point must be on an option heading (level 2 or deeper)")
    (let ((title (my/manifolding-atlas-org-prompt--normalize-choice
                  (org-get-heading t t t t))))
      (if my/manifolding-atlas-org-prompt--session-p
          (my/manifolding-atlas-org-prompt--accept-session)
        (my/manifolding-atlas-org-prompt--accept-standalone title)))))

(defun my/manifolding-atlas-org-prompt--highlight-applied (title)
  "Overlay the currently applied option, mirroring mark styling."
  (remove-overlays (point-min) (point-max) 'atlas-applied t)
  (when title
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward
             (format "^\\*\\*+ %s[ \t]*$" (regexp-quote title)) nil t)
        (let ((ov (make-overlay (line-beginning-position)
                                (line-end-position))))
          (overlay-put ov 'atlas-applied t)
          (overlay-put ov 'face 'bold))))))

(defun my/manifolding-atlas-org-prompt--toggle-collection (title)
  "Toggle TITLE among the session's marks, applying live."
  (let ((marks (if (member title my/manifolding-atlas-org-prompt--buffer-marks)
                   (delete title my/manifolding-atlas-org-prompt--buffer-marks)
                 (cons title my/manifolding-atlas-org-prompt--buffer-marks))))
    (setq my/manifolding-atlas-org-prompt--buffer-marks marks)
    (if marks
        (progn
          (setq my/manifolding-atlas-org-prompt--applied
                (string-join marks " "))
          (my/manifolding-atlas-org-prompt--session-apply
           my/manifolding-atlas-org-prompt--applied))
      (my/manifolding-atlas-org-prompt--session-remove)
      (setq my/manifolding-atlas-org-prompt--applied nil))
    (my/manifolding-atlas-org-prompt--highlight-applied
     my/manifolding-atlas-org-prompt--applied)
    (message "%s" (or my/manifolding-atlas-org-prompt--applied
                      "cleared"))))

(defun my/manifolding-atlas-org-prompt--toggle-scalar (title)
  "Apply TITLE to the session note, or remove it when already applied."
  (if (and my/manifolding-atlas-org-prompt--applied
           (string= my/manifolding-atlas-org-prompt--applied title))
      (progn
        (my/manifolding-atlas-org-prompt--session-remove)
        (setq my/manifolding-atlas-org-prompt--applied nil)
        (my/manifolding-atlas-org-prompt--highlight-applied nil)
        (message "%s removed from note" title))
    (my/manifolding-atlas-org-prompt--session-apply title)
    (setq my/manifolding-atlas-org-prompt--applied title)
    (my/manifolding-atlas-org-prompt--highlight-applied title)
    (message "%s → note" title)))

(defun my/manifolding-atlas-org-prompt--toggle-apply ()
  "Apply the option at point to the target note — or remove it when
it was the one already applied.  Live: every change lands on disk and
shows in the note window immediately."
  (let* ((req (plist-get my/manifolding-atlas-org-prompt--session :current))
         (spec (plist-get req :spec))
         (kind (plist-get spec :kind))
         (title (my/manifolding-atlas-org-prompt--normalize-choice
                 (org-get-heading t t t t))))
    (if (memq kind '(multi tags))
        (my/manifolding-atlas-org-prompt--toggle-collection title)
      (my/manifolding-atlas-org-prompt--toggle-scalar title))))

(defun my/manifolding-atlas-org-prompt--live-finalized ()
  "After the live-ref capture finalizes, continue remaining prompts."
  (remove-hook 'org-capture-after-finalize-hook
               #'my/manifolding-atlas-org-prompt--live-finalized)
  (when (plist-get my/manifolding-atlas-org-prompt--session :note)
    (my/manifolding-atlas-org-prompt--session-next)))

(defun my/manifolding-atlas-org-prompt--live-ref-path (family val ref-id ref-note)
  "Return REF-NOTE's path, creating a fallback file under admin/refs."
  (or (and ref-note (manifolding-atlas-note-path ref-note))
      (let ((p (expand-file-name
                (format "admin/refs/%s/%s" family val)
                (my/manifolding-atlas-root-dir))))
        (make-directory (file-name-directory p) t)
        (unless (file-exists-p p)
          (with-temp-file p
            (insert (format "* %s\n:PROPERTIES:\n:ID: %s\n:END:\n"
                            val ref-id)))
          (org-id-add-location ref-id p))
        p)))

(defun my/manifolding-atlas-org-prompt--capture-ref-content (ref-path)
  "Open REF-PATH capture-style so the ref note gets its content."
  (add-hook 'org-capture-after-finalize-hook
            #'my/manifolding-atlas-org-prompt--live-finalized)
  (let ((org-capture-templates
         `(("l" "Live ref note" plain
            (file+function ,ref-path
                           (lambda () (goto-char (point-max))))
            "\n%?\n" :kill-buffer t :unnarrowed t)))
        (org-capture-use-indirect-buffer nil))
    (org-capture nil "l")))

(defun my/manifolding-atlas-org-prompt--make-live ()
  "Upgrade the applied option into a live ref-note property.
Creates (or reuses) the ref note under admin/refs/FAMILY/, points
the note's property at it with an id link, then opens the ref note
in an org-capture buffer.  C-c C-c there saves and continues with
the rest of the prompts."
  (interactive)
  (unless my/manifolding-atlas-org-prompt--session-p
    (user-error "Only in an active prompt session"))
  (unless my/manifolding-atlas-org-prompt--applied
    (user-error "Nothing applied yet — press m first"))
  (let* ((req (plist-get my/manifolding-atlas-org-prompt--session :current))
         (spec (plist-get req :spec))
         (note (plist-get my/manifolding-atlas-org-prompt--session :note))
         (key (plist-get spec :key))
         (family (intern
                  (downcase
                   (or (plist-get (plist-get spec :plist) :live)
                       (replace-regexp-in-string "_" "-" key)))))
         (val my/manifolding-atlas-org-prompt--applied)
         (link (my/manifolding-atlas--ensure-ref-note family val))
         (ref-id (my/manifolding-atlas--id-from-link link))
         (ref-note (condition-case nil
                       (manifolding-atlas-db-get-by-id ref-id)
                     (error nil)))
         (ref-path (my/manifolding-atlas-org-prompt--live-ref-path
                    family val ref-id ref-note)))
    ;; Upgrade the plain value to an id-link on the target note.
    (let ((my/manifolding-atlas--quiet t))
      (my/manifolding-atlas-org-prompt--apply-to-note
       note (list (cons key link)) nil nil))
    ;; Record the pick, close the picker, then capture ref content.
    (my/manifolding-atlas-org-prompt--session-record-answer)
    (my/manifolding-atlas-org-prompt--buffer-finish)
    (my/manifolding-atlas-org-prompt--capture-ref-content ref-path)))

(defun my/manifolding-atlas-org-prompt--edit-property-file ()
  "Make the picker buffer directly editable in place.
The picker buffer visits the property file, so editing here and
saving with C-x C-s writes the file itself."
  (interactive)
  (setq buffer-read-only nil)
  (when (fboundp 'modaled-set-state)
    (modaled-set-state nil))
  (message "Editing property file in place — C-x C-s to save"))

(defun my/manifolding-atlas-org-prompt--ks-to-option ()
  "Select an option line with key selection; the cursor lands on it.
Marking is manual afterwards — use buffer-mark on that line."
  (interactive)
  (ks-with my/manifolding-atlas-org-prompt-ks
    (let ((r (ks--line (eq current-prefix-arg 4))))
      (when (and (not (memq r '(t nil))) (eq ks-action #'identity))
        (goto-char r)
        (if (and (org-at-heading-p) (>= (org-outline-level) 2))
            (message "Option: %s"
                     (my/manifolding-atlas-org-prompt--normalize-choice
                      (org-get-heading t t t t)))
          (user-error "Not an option heading"))))))

(defun my/manifolding-atlas-org-prompt--ks-mark-loop (buf)
  "Key-selection-first marking loop over picker BUF.
The selector stays armed the whole time the picker is open: typing
letters jumps to an option and applies it live; you can keep jumping
and re-mark to change the selection. RET advances only when something
is marked; C-q quits, C-l makes live, C-e edits the property file."
  (let ((exit-loop nil))
    (while (and (not exit-loop) (buffer-live-p buf))
      (when-let ((win (get-buffer-window buf)))
        (with-selected-window win
          (let ((ks-all-windows nil))
            (condition-case nil
                (progn (ks-goto-line)
                       (when (and (org-at-heading-p)
                                  (>= (org-outline-level) 2))
                         (my/manifolding-atlas-org-prompt--buffer-mark)))
              (user-error nil)
              (error nil)))))
      (let ((key (read-key "jump to mark · RET advance · SPC back · C-q quit · C-l live · C-e edit")))
        (cond
         ((eq key 32)
          (if (or my/manifolding-atlas-org-prompt--applied
                  my/manifolding-atlas-org-prompt--buffer-marks)
              (setq exit-loop 'back)
            (message "Nothing applied — mark an option first")))
         ((eq key ?\r)
          (if (or my/manifolding-atlas-org-prompt--applied
                  my/manifolding-atlas-org-prompt--buffer-marks)
              (setq exit-loop 'accept)
            (message "Mark an option first — or C-q to quit")))
         ((eq key ?\C-q) (setq exit-loop 'skip))
         ((eq key ?\C-l) (setq exit-loop 'live))
         ((eq key ?\C-e) (setq exit-loop 'edit))
         (t nil))))
    (when (buffer-live-p buf)
      (pcase exit-loop
        ('accept (my/manifolding-atlas-org-prompt--buffer-accept))
        ('skip   (my/manifolding-atlas-org-prompt--buffer-abort))
        ('live   (my/manifolding-atlas-org-prompt--make-live))
        ('edit   (my/manifolding-atlas-org-prompt--edit-property-file))
        ('back   (my/manifolding-atlas-org-prompt--session-back))))))

(defun my/manifolding-atlas-org-prompt--buffer-mark ()
  "Session: apply/un-apply the option at point live.
Standalone pickers keep classic multi-mark behavior."
  (interactive)
  (if (not (and (org-at-heading-p) (>= (org-outline-level) 2)))
      (message "Point must be on an option heading")
    (if my/manifolding-atlas-org-prompt--session-p
        (my/manifolding-atlas-org-prompt--toggle-apply)
      (let ((title (org-get-heading t t t t)))
        (setq my/manifolding-atlas-org-prompt--buffer-marks
              (if (member title my/manifolding-atlas-org-prompt--buffer-marks)
                  (delq title my/manifolding-atlas-org-prompt--buffer-marks)
                (cons title my/manifolding-atlas-org-prompt--buffer-marks)))
        (my/manifolding-atlas-org-prompt--buffer-refresh-marks)))))

(defun my/manifolding-atlas-org-prompt--session-cancel ()
  "Cancel the entire capture: drop every queued prompt and delete
the draft note file.  The finalizer never runs."
  (let* ((note (plist-get my/manifolding-atlas-org-prompt--session :note))
         (file (and note (manifolding-atlas-note-path note))))
    (setq my/manifolding-atlas-org-prompt--pending-create nil)
    (my/manifolding-atlas-org-prompt--sweep-pickers)
    (setq my/manifolding-atlas-org-prompt--session nil)
    (when (and file (file-exists-p file))
      (ignore-errors (delete-file file))
      (message "Capture aborted — %s discarded"
               (file-name-nondirectory file)))))

(defun my/manifolding-atlas-org-prompt--session-skip (req prev-applied)
  "Settle REQ's answer to PREV-APPLIED (or WARNING) and advance.
Must run while the picker buffer is still current."
  (if prev-applied
      (progn
        (setq my/manifolding-atlas-org-prompt--applied prev-applied)
        (my/manifolding-atlas-org-prompt--session-record-answer)
        (my/manifolding-atlas-org-prompt--buffer-finish)
        (my/manifolding-atlas-org-prompt--session-next))
    (let ((my/manifolding-atlas--quiet t))
      (my/manifolding-atlas-org-prompt--session-apply
       (or (plist-get req :default) "WARNING")))
    (my/manifolding-atlas-org-prompt--buffer-finish)
    (my/manifolding-atlas-org-prompt--session-next)))

(defun my/manifolding-atlas-org-prompt--quit-all ()
  "C-g / Q in a picker: abort everything.
In an async session this cancels the capture and deletes the draft.
Standalone pickers just exit with no result."
  (interactive)
  (if my/manifolding-atlas-org-prompt--session-p
      (progn
        (my/manifolding-atlas-org-prompt--buffer-finish)
        (my/manifolding-atlas-org-prompt--session-cancel))
    (setq my/manifolding-atlas-org-prompt--buffer-result nil)
    (my/manifolding-atlas-org-prompt--buffer-finish)
    (exit-recursive-edit)))

(defun my/manifolding-atlas-org-prompt--buffer-abort ()
  "Cancel selection; inside a session skip to the next pending prompt."
  (interactive)
  (if my/manifolding-atlas-org-prompt--session-p
      (let* ((req (plist-get my/manifolding-atlas-org-prompt--session :current))
             (prev-applied (or my/manifolding-atlas-org-prompt--applied
                               (and req (plist-get req :applied-value)))))
        (when (and req prev-applied)
          (plist-put req :applied-value prev-applied))
        ;; Record/apply BEFORE killing the picker buffer: both
        ;; `--session-record-answer' and `--session-apply' read the
        ;; buffer-local `--applied' value and must run while the
        ;; picker buffer is still current (see their docstrings).
        (my/manifolding-atlas-org-prompt--session-skip req prev-applied))
    (setq my/manifolding-atlas-org-prompt--buffer-result nil)
    (my/manifolding-atlas-org-prompt--buffer-finish)
    (exit-recursive-edit)))

(defvar my/manifolding-atlas-org-prompt--session nil
  "Active async session plist: :pending, :current, :note, :finalize.")

(defvar my/manifolding-atlas-org-prompt--pending-create nil
  "Parked deferred prompts awaiting note creation in default-function flows.")

(defvar-local my/manifolding-atlas-org-prompt--session-p nil
  "Non-nil in picker buffers driven by an async session.")

(defun my/manifolding-atlas-org-prompt--base-key (key)
  "Return the declarative spec key behind registry KEY."
  (if (string-suffix-p "--task" (symbol-name key))
      (intern (substring (symbol-name key) 0 -6))
    key))

(defun my/manifolding-atlas-org-prompt--park-deferred ()
  "Move the deferred queue into the pending-create parking list.
Used by creation paths where the note does not exist yet when prompts
are collected (default-function flows); the parked queue is started by
the post-create advice once the note exists."
  (setq my/manifolding-atlas-org-prompt--pending-create
        (append my/manifolding-atlas-org-prompt--pending-create
                my/manifolding-atlas-org-prompt--deferred
                nil))
  (setq my/manifolding-atlas-org-prompt--deferred nil))

(defun my/manifolding-atlas-org-prompt--sweep-pickers ()
  "Kill every leftover picker buffer from this or an interrupted session."
  (let ((note-buf (when-let ((note (plist-get my/manifolding-atlas-org-prompt--session :note))
                             (path (and note (manifolding-atlas-note-path note))))
                    (get-file-buffer path))))
    (dolist (buf (buffer-list))
      (when (and (buffer-live-p buf)
                 (buffer-local-value
                  'my/manifolding-atlas-org-prompt--session-p buf))
        (let ((placed nil))
          (dolist (win (get-buffer-window-list buf nil t))
            (when (window-live-p win)
              (if (and (not placed)
                       (= 1 (length (window-list (window-frame win) 'no-minibuf)))
                       note-buf (buffer-live-p note-buf))
                  (progn (set-window-buffer win note-buf) (setq placed t))
                (ignore-errors (delete-window win))))))
        (condition-case nil (kill-buffer buf) (error nil))))))

(defun my/manifolding-atlas-org-prompt--session-begin (queue note finalize)
  "Start answering QUEUE for NOTE; call FINALIZE when drained."
  (setq my/manifolding-atlas-org-prompt--session
        (list :note note :pending queue :answered nil
              :finalize finalize))
  (my/manifolding-atlas-org-prompt--session-next))

(defun my/manifolding-atlas-org-prompt--session-record-answer ()
  "Move the session's :current request onto :answered, remembering
what was applied so revisits can highlight and un-apply correctly.
Must run while the picker buffer is still current."
  (let ((req (plist-get my/manifolding-atlas-org-prompt--session :current)))
    (when req
      (plist-put req :applied-value
                 my/manifolding-atlas-org-prompt--applied)
      (plist-put my/manifolding-atlas-org-prompt--session
                 :answered
                 (cons req
                       (plist-get my/manifolding-atlas-org-prompt--session
                                  :answered))))))

(defun my/manifolding-atlas-org-prompt--session-reopen (req)
  "Kill the current picker and reopen the already-answered REQ.
Restores the applied highlight from the recorded value; RET then
simply continues forward without re-applying anything."
  (plist-put my/manifolding-atlas-org-prompt--session :current req)
  (my/manifolding-atlas-org-prompt--session-open req))

(defun my/manifolding-atlas-org-prompt--session-requeue (cur)
  "Move CUR from :current back onto the front of :pending."
  (when cur
    (plist-put my/manifolding-atlas-org-prompt--session
               :pending
               (cons cur
                     (plist-get my/manifolding-atlas-org-prompt--session
                                :pending)))))

(defun my/manifolding-atlas-org-prompt--session-back ()
  "Step back to the most recently answered prompt."
  (interactive)
  (unless my/manifolding-atlas-org-prompt--session-p
    (user-error "Only in an active prompt session"))
  (let ((answered (plist-get my/manifolding-atlas-org-prompt--session
                             :answered)))
    (if (null answered)
        (user-error "Nothing to go back to")
      (my/manifolding-atlas-org-prompt--buffer-finish)
      (let ((prev (car answered))
            (cur (plist-get my/manifolding-atlas-org-prompt--session
                            :current)))
        (plist-put my/manifolding-atlas-org-prompt--session
                   :answered (cdr answered))
        (my/manifolding-atlas-org-prompt--session-requeue cur)
        (message "Back to: %s"
                 (plist-get (plist-get prev :spec) :label))
        (my/manifolding-atlas-org-prompt--session-reopen prev)))))

(defun my/manifolding-atlas-org-prompt--session-pick-answered (answered)
  "Completing-read an answered REQ from ANSWERED by label."
  (let* ((cands (mapcar (lambda (req)
                          (cons (plist-get (plist-get req :spec) :label)
                                req))
                        answered))
         (choice (completing-read
                  "Revisit prompt: "
                  (mapcar #'car cands)
                  nil t)))
    (cdr (assoc choice cands))))

(defun my/manifolding-atlas-org-prompt--session-revisit ()
  "Pick any already-answered prompt and reopen it."
  (interactive)
  (unless my/manifolding-atlas-org-prompt--session-p
    (user-error "Only in an active prompt session"))
  (let ((answered (plist-get my/manifolding-atlas-org-prompt--session
                             :answered)))
    (if (null answered)
        (user-error "Nothing to revisit yet")
      (my/manifolding-atlas-org-prompt--buffer-finish)
      (let* ((req (my/manifolding-atlas-org-prompt--session-pick-answered
                   answered))
             (choice (plist-get (plist-get req :spec) :label))
             (cur (plist-get my/manifolding-atlas-org-prompt--session
                             :current)))
        (plist-put my/manifolding-atlas-org-prompt--session
                   :answered (delq req answered))
        (my/manifolding-atlas-org-prompt--session-requeue cur)
        (message "Revisiting: %s" choice)
        (my/manifolding-atlas-org-prompt--session-reopen req)))))

(defun my/manifolding-atlas-org-prompt--session-maybe-start (note &optional finalize)
  "Answer any deferred prompts against NOTE, then call FINALIZE.
SKIP ALL · NO BODY mode (fast level 3) skips every queued prompt."
  (let ((queue my/manifolding-atlas-org-prompt--deferred))
    (setq my/manifolding-atlas-org-prompt--deferred nil)
    (if (and queue (/= (my/manifolding-atlas--fast-level) 3))
        (my/manifolding-atlas-org-prompt--session-begin queue note finalize)
      (when finalize (funcall finalize)))))

(defun my/manifolding-atlas-org-prompt--session-start-parked (note &optional finalize)
  "Answer parked prompts against NOTE, then call FINALIZE.
SKIP ALL · NO BODY mode (fast level 3) skips every parked prompt."
  (let ((queue my/manifolding-atlas-org-prompt--pending-create))
    (setq my/manifolding-atlas-org-prompt--pending-create nil)
    (if (and queue (/= (my/manifolding-atlas--fast-level) 3))
        (my/manifolding-atlas-org-prompt--session-begin queue note finalize)
      (when finalize (funcall finalize)))))

(defun my/manifolding-atlas-org-prompt--session-next ()
  (let ((queue (plist-get my/manifolding-atlas-org-prompt--session :pending)))
    (if (null queue)
        (my/manifolding-atlas-org-prompt--session-finish)
      (plist-put my/manifolding-atlas-org-prompt--session
                 :pending (cdr queue))
      (plist-put my/manifolding-atlas-org-prompt--session
                 :current (car queue))
      (my/manifolding-atlas-org-prompt--session-open (car queue)))))

(defun my/manifolding-atlas-org-prompt--session-finish ()
  "Drained the queue: clean up, restore the frame, run the finalizer."
  (let* ((note (plist-get my/manifolding-atlas-org-prompt--session :note))
         (finalize (plist-get my/manifolding-atlas-org-prompt--session
                              :finalize)))
    (let ((my/manifolding-atlas--quiet t))
      (my/manifolding-atlas-org-prompt--sweep-pickers)
      (setq my/manifolding-atlas-org-prompt--session nil)
      (when (and note
                 (manifolding-atlas-note-path note)
                 (file-exists-p (manifolding-atlas-note-path note)))
        (pop-to-buffer (find-file-noselect (manifolding-atlas-note-path note)))))
    (when finalize (funcall finalize))))

(defun my/manifolding-atlas-org-prompt--ensure-warning-option ()
  "Ensure a first `** WARNING' option exists under the prompt key.
Inserts it right after the level-1 key heading (past its property
drawer) when missing, leaving point on that heading.  The buffer is
persisted by `my/manifolding-atlas-org-prompt--buffer-finish', so each
prompt file self-heals permanently on first visit."
  (goto-char (point-min))
  (if (re-search-forward "^\\*\\*+ WARNING[ \t]*$" nil t)
      (beginning-of-line)
    (goto-char (point-min))
    (when (re-search-forward "^\\* \\([^ \t\n][^\n]*\\)[ \t]*$" nil t)
      (beginning-of-line)
      (forward-line 1)
      (when (looking-at "^[ \t]*:PROPERTIES:[ \t]*$")
        (while (and (not (eobp))
                    (not (looking-at "^[ \t]*:END:[ \t]*$")))
          (forward-line 1))
        (forward-line 1))
      (insert "** WARNING\n")
      (forward-line -1))))

(defun my/manifolding-atlas--display-buffer-responsive (buf)
  "Show BUF in a dedicated window, sized to fit safely.
Never falls back to `pop-to-buffer', which would clobber whatever
window currently has focus (dired, an org buffer, etc.)."
  (let ((height-frac (if (> (frame-width) 140) 0.5 0.35)))
    (display-buffer
     buf
     `((display-buffer-reuse-window display-buffer-at-bottom)
       (window-height . ,height-frac)
       (window-min-height . 4)))))

(defun my/manifolding-atlas-org-prompt--session-display (buf)
  (let* ((note (plist-get my/manifolding-atlas-org-prompt--session :note))
         (note-buf (and note (manifolding-atlas-note-path note)
                        (condition-case err
                            (find-file-noselect (manifolding-atlas-note-path note))
                          (error (warn "atlas-prompt note-buf: %s" (error-message-string err)) nil)))))
    (when (buffer-live-p note-buf)
      (set-window-buffer (selected-window) note-buf))
    (my/manifolding-atlas--display-buffer-responsive buf)))

(defun my/manifolding-atlas-org-prompt--picker-buffer (file)
  "Return an org buffer visiting FILE, creating a bare one if needed."
  (condition-case nil
      (find-file-noselect file)
    (error
     (or (get-file-buffer file)
         (with-current-buffer
             (get-buffer-create (file-name-nondirectory file))
           (unless (derived-mode-p 'org-mode)
             (ignore-errors (org-mode)))
           (current-buffer))))))

(defun my/manifolding-atlas-org-prompt--jump-default (default)
  "Land point on DEFAULT's option heading, else on WARNING."
  (goto-char (point-min))
  (if (and default (not (string-empty-p default)))
      (when (re-search-forward
             (format "^\\*\\*+ %s[ \t]*$" (regexp-quote default))
             nil t)
        (beginning-of-line))
    (when (re-search-forward "^\\*\\*+ WARNING[ \t]*$" nil t)
      (beginning-of-line))))

(defun my/manifolding-atlas-org-prompt--session-arm (buf req spec)
  "Prepare picker BUF for REQ described by SPEC."
  (with-current-buffer buf
    (when (bound-and-true-p org-tree-slide-mode)
      (org-tree-slide-mode -1))
    (widen)
    (outline-show-all)
    (my/manifolding-atlas-org-prompt--ensure-warning-option)
    (my/manifolding-atlas-org-prompt--jump-default
     (plist-get req :default))
    (setq my/manifolding-atlas-org-prompt--buffer-result nil)
    (setq my/manifolding-atlas-org-prompt--buffer-marks nil)
    (setq my/manifolding-atlas-org-prompt--applied
          (plist-get req :applied-value))
    (setq my/manifolding-atlas-org-prompt--this-kind
          (plist-get spec :kind))
    (setq my/manifolding-atlas-org-prompt--session-p t)
    (when (fboundp 'modaled-set-state)
      (modaled-set-state "atlas-pick"))
    (my/manifolding-atlas-org-prompt--highlight-applied
     my/manifolding-atlas-org-prompt--applied)))

(defun my/manifolding-atlas-org-prompt--session-open (req)
  "Display the prompt file for REQ and arm the picker."
  (let* ((spec (plist-get req :spec))
         (file (plist-get spec :file))
         (buf (my/manifolding-atlas-org-prompt--picker-buffer file)))
    (my/manifolding-atlas-org-prompt--session-arm buf req spec)
    (my/manifolding-atlas-org-prompt--session-display buf)
    ;; Re-assert the modal state AFTER display: window/buffer churn
    ;; re-runs modaled's init hooks, which reset fresh org buffers to
    ;; the major-mode default ("org") — leaving the picker keyless.
    (with-current-buffer buf
      (when (fboundp 'modaled-set-state)
        (modaled-set-state "atlas-pick")))
    (when-let ((win (get-buffer-window buf)))
      (with-selected-window win
        (ignore-errors (recenter-top-bottom))))
    (message "%s — letters jump+mark · RET advance · C-q quit · C-l live · C-e edit"
             (plist-get spec :label))
    ;; Arm the key-selection-first marking loop: letters jump and mark
    ;; by default, only RET advances, C-q/C-l/C-e are the controls.
    (my/manifolding-atlas-org-prompt--ks-mark-loop buf)))

(defun my/manifolding-atlas-org-prompt--session-value (title)
  "Return the effective value for picking TITLE in the current request."
  (let* ((req (plist-get my/manifolding-atlas-org-prompt--session :current))
         (spec (plist-get req :spec))
         (default (plist-get req :default)))
    (cond
     ((and (eq (plist-get spec :kind) 'multi)
           title
           my/manifolding-atlas-org-prompt--buffer-marks)
      (string-join
       (mapcar #'my/manifolding-atlas-org-prompt--normalize-choice
               (reverse my/manifolding-atlas-org-prompt--buffer-marks))
       " "))
     ((null title)
       (or default "WARNING"))
      (t title))))

(defun my/manifolding-atlas-org-prompt--write-at-heading
    (pos level props tags todo remove-props)
  "Write PROPS/TAGS/TODO at the heading anchor; return park position.
REMOVE-PROPS lists property keys to delete instead."
  (save-excursion
    (cond ((and level (> level 0) pos)
           (goto-char pos)
           (org-back-to-heading t))
          (t (goto-char (point-min))))
    (dolist (p props)
      (org-entry-put nil (car p) (cdr p)))
    (dolist (rk remove-props)
      (condition-case nil (org-entry-delete nil rk) (error nil)))
    (when tags
      (org-set-tags tags))
    (cond
     ((eq todo 'none)
      (ignore-errors (org-todo 'none)))
     ((and todo (not (member todo '("WARNING" ""))))
      ;; org-todo only accepts keywords declared in the buffer's TODO
      ;; sequence; schema states (NEXT, DOING, WAIT...) may not be —
      ;; fall back to setting the keyword textually on the heading.
      (condition-case nil
          (org-todo todo)
         (error
          (org-back-to-heading t)
          (beginning-of-line)
          (when (looking-at "^\\*+\\s-*")
            (goto-char (match-end 0))
            (when (looking-at "[A-Za-z]+ ")
              (delete-region (point) (match-end 0)))
            (insert todo " "))
          ;; The keyword was inserted textually (not via org-todo), so
          ;; org's font-lock/heading regexps don't know it yet — refresh
          ;; them or redisplay trips "No match 2 ... org-headline-done".
          (org-set-regexps-and-options)))))
    ;; Park the view ON the heading so TODO/keyword changes are
    ;; visible while the session picks are applied.
    (save-excursion
      (org-back-to-heading t)
      (point))))

(defun my/manifolding-atlas-org-prompt--apply-to-note
    (note props tags todo &optional remove-props)
  "Write PROPS, TAGS and TODO at NOTE's heading in its buffer, save,
then park the note window centered on the heading."
  (let* ((file (manifolding-atlas-note-path note))
         (buf (find-file-noselect file))
         view-target)
    (with-current-buffer buf
      (setq view-target
            (my/manifolding-atlas-org-prompt--write-at-heading
             (manifolding-atlas-note-pos note)
             (manifolding-atlas-note-level note)
             props tags todo remove-props))
      (save-buffer))
    ;; Park the note window on the heading WITHOUT selecting it: selecting
    ;; the note window here steals focus out of the picker's read-key
    ;; loop, re-entrantly destabilizing it (double toggles, buffer churn).
    (when-let ((win (get-buffer-window buf t)))
      (set-window-point win (or view-target (point-min)))
      (with-selected-window win (recenter nil)))))

(defun my/manifolding-atlas-org-prompt--session-remove ()
  "Remove the current request's value from the target note.
The inverse of a pick: scalar properties are deleted, tags are
cleared, TODO keywords are removed from the heading."
  (let* ((req (plist-get my/manifolding-atlas-org-prompt--session :current))
         (spec (plist-get req :spec))
         (note (plist-get my/manifolding-atlas-org-prompt--session :note))
         (kind (plist-get spec :kind))
         (prop (plist-get spec :key)))
    (when note
      (let ((my/manifolding-atlas--quiet t))
        (cond
         ((eq kind 'todo)
          (my/manifolding-atlas-org-prompt--apply-to-note note nil nil 'none))
         ((memq kind '(tags tagopt))
          (my/manifolding-atlas-org-prompt--apply-to-note note nil nil nil))
          (t
           (my/manifolding-atlas-org-prompt--apply-to-note
            note nil nil nil (list prop))))))))

(defun my/manifolding-atlas-org-prompt--run-post-apply (post note)
  "Run POST hooks against NOTE, reporting each failure."
  (dolist (fn post)
    (condition-case err
        (funcall fn note)
      (error
       (message "atlas prompt post-apply: %s"
                (error-message-string err))))))

(defun my/manifolding-atlas-org-prompt--session-apply (val)
  "Apply VAL for the current request directly to the session note."
  (let* ((req (plist-get my/manifolding-atlas-org-prompt--session :current))
         (spec (plist-get req :spec))
         (note (plist-get my/manifolding-atlas-org-prompt--session :note))
         (frag (my/manifolding-atlas-org-prompt--fragment
                (plist-get spec :key)
                (plist-get spec :kind)
                (plist-get spec :plist)
                val)))
    (when (and note frag)
      (let ((props (plist-get frag :properties))
            (tags (plist-get frag :tags))
            (todo (plist-get frag :todo))
            (post (plist-get frag :post-apply)))
        (let ((my/manifolding-atlas--quiet t))
          (when (or props tags todo)
            (my/manifolding-atlas-org-prompt--apply-to-note
             note props tags todo)))
        (my/manifolding-atlas-org-prompt--run-post-apply post note)))))

(defvar-local my/manifolding-atlas-org-prompt--this-kind nil)

(defun my/manifolding-atlas-org-prompt--buffer-finish ()
  "Persist option edits, then kill the picker buffer and manage its window."
  (when (and buffer-file-name (buffer-modified-p))
    (save-buffer))
  (when (fboundp 'my/smart-escape)
    (my/smart-escape))
   (let ((buf (current-buffer))
         (note-buf (when-let ((note (plist-get my/manifolding-atlas-org-prompt--session :note))
                              (path (and note (manifolding-atlas-note-path note))))
                     (get-file-buffer path))))
     (let ((placed nil))
       (dolist (win (get-buffer-window-list buf nil t))
         (when (window-live-p win)
           (if (and (not placed)
                    (= 1 (length (window-list (window-frame win) 'no-minibuf)))
                    note-buf (buffer-live-p note-buf))
               (progn (set-window-buffer win note-buf) (setq placed t))
             (ignore-errors (delete-window win))))))
     (kill-buffer buf)))

(defun my/manifolding-atlas-org-prompt--standalone-setup (buf default kind)
  "Arm BUF as a standalone picker for KIND, landing on DEFAULT."
  (with-current-buffer buf
    (when (bound-and-true-p org-tree-slide-mode)
      (org-tree-slide-mode -1))
    (widen)
    (outline-show-all)
    (goto-char (point-min))
    (when (re-search-forward "^\\*\\*+ " nil t)
      (beginning-of-line))
    (when (and default (not (string-empty-p default)))
      (goto-char (point-min))
      (when (re-search-forward
             (format "^\\*\\*+ %s[ \t]*$"
                     (regexp-quote default))
             nil t)
        (beginning-of-line)))
    (setq my/manifolding-atlas-org-prompt--session-p nil)
    (when (fboundp 'modaled-set-state)
      (modaled-set-state "atlas-pick"))
    (setq my/manifolding-atlas-org-prompt--this-kind kind)))

(defun my/manifolding-atlas-org-prompt--ask-buffer (file kind default)
   "Open FILE capture-style and let the user pick an option."
   (setq my/manifolding-atlas-org-prompt--buffer-result nil)
   (setq my/manifolding-atlas-org-prompt--buffer-marks nil)
   (let ((buf (my/manifolding-atlas-org-prompt--picker-buffer file)))
     (my/manifolding-atlas-org-prompt--standalone-setup buf default kind)
     (let ((height-frac (if (> (frame-width) 140) 0.5 0.35)))
       (display-buffer
        buf
        `((display-buffer-reuse-window display-buffer-at-bottom)
          (window-height . ,height-frac)
          (window-min-height . 4))))
     (with-current-buffer buf
       (when (fboundp 'modaled-set-state)
         (modaled-set-state "atlas-pick")))
    (ignore-errors (recenter-top-bottom))
    (message "Option picker — RET/C-c C-c select · m mark · C-c C-k/q cancel")
    (recursive-edit)
    my/manifolding-atlas-org-prompt--buffer-result))

(defun my/manifolding-atlas-org-prompt--ask-mindmap (choice)
  "Resolve a mindmap CHOICE into a placement plist."
  (cond
   ((and (stringp choice)
         (member choice '("parent" "child" "sibling")))
    (let ((target (manifolding-atlas-select
                   (pcase choice
                     ("parent"
                      "Child to place under this note: ")
                     ("child"
                      "Parent for this note: ")
                     ("sibling"
                      "Place after this note: "))
                   :require-match t)))
      (list :placement choice
            :target-id (when target
                         (manifolding-atlas-note-id target)))))
   ((stringp choice)
    (list :placement "root" :target-id nil))
   (t "WARNING")))

(defun my/manifolding-atlas-org-prompt--ask
    (file key label kind options plist default)
  (if (and (eq my/manifolding-atlas-org-prompt-ui 'buffer)
           file (file-exists-p file)
           (memq kind '(property live todo multi tagopt mindmap
                        scoped mastering)))
      (let ((choice (my/manifolding-atlas-org-prompt--ask-buffer
                     file kind default)))
        (if (eq kind 'mindmap)
            (my/manifolding-atlas-org-prompt--ask-mindmap choice)
          (or choice (if default default "WARNING"))))
    (my/manifolding-atlas-org-prompt--ask-minibuffer
     key label kind options plist default)))

(defun my/manifolding-atlas-org-prompt--ask-topics (key)
  "Ask for rule topics known to the database, stored on KEY."
  (let* ((current (org-entry-get nil key))
         (known (mapcar #'car
                        (emacsql (manifolding-atlas-db)
                                 [:select :distinct [primary-topic]
                                  :from rules])))
         (defaults (when current (split-string current " " t))))
    (mapconcat #'identity
               (completing-read-multiple
                "Topics (comma-sep, first=primary, blank=universal): "
                known nil nil nil nil defaults)
               " ")))

(defun my/manifolding-atlas-org-prompt--ask-tags (options)
  "Ask for comma-separated tags over OPTIONS plus database tags."
  (let* ((db-tags (condition-case nil
                      (manifolding-atlas-db-query-tags)
                    (error nil)))
         (cands (append '("tag-warning") options db-tags))
         (input (completing-read
                 "Tags (comma-separated, tag-warning skips): "
                 cands nil nil nil nil "tag-warning")))
    (if (or (string-empty-p input)
            (string= input "tag-warning"))
        '("tag-warning")
      (delete-dups
       (cl-remove-if #'string-empty-p
                     (split-string input "[ \t]*,[ \t]*" t))))))

(defun my/manifolding-atlas-org-prompt--ask-multi (label options)
  "Ask for multiple values over LABEL/OPTIONS, blank = skip."
  (let* ((raw (completing-read-multiple
               (format "%s (comma-separated, blank = skip): " label)
               (cons "WARNING" options) nil nil))
         (vals (delete-dups
                (cl-remove-if
                 (lambda (v)
                   (or (string-empty-p v)
                       (string-equal v "WARNING")))
                 raw))))
    (if vals (string-join vals " ") "WARNING")))

(defun my/manifolding-atlas-org-prompt--ask-options (label options default)
  "Completing-read one option; WARNING falls back to DEFAULT."
  (let ((val (completing-read
              (format "%s: " label)
              (cons "WARNING" options)
              nil t nil nil (or default "WARNING"))))
    (if (string-equal val "WARNING")
        (if default default "WARNING")
      val)))

(defun my/manifolding-atlas-org-prompt--ask-minibuffer
    (key label kind options plist default)
  (pcase kind
    ('template
      (my/manifolding-atlas-prompt-template--choose))
    ('free
      (let ((val (read-string (format "%s: " label) nil nil
                              (or default "WARNING"))))
        (if (string-empty-p val) "WARNING" val)))
    ('topics (my/manifolding-atlas-org-prompt--ask-topics key))
    ('tags (my/manifolding-atlas-org-prompt--ask-tags options))
    ('multi (my/manifolding-atlas-org-prompt--ask-multi label options))
    ('tagopt
      (let ((sentinel (or default "auto")))
        (completing-read (format "%s: " label)
                         (cons sentinel options)
                         nil t nil nil sentinel)))
    (_
      (my/manifolding-atlas-org-prompt--ask-options
       label options default))))

(defun my/manifolding-atlas-org-prompt--fragment-todo (val)
  `(:todo ,val
    :post-apply (,(apply-partially
                   #'my/manifolding-atlas--post-sync "TODO" val))))

(defun my/manifolding-atlas-org-prompt--fragment-tags (val)
  (when val
    `(:tags ,val
      :post-apply (,(apply-partially
                     #'my/manifolding-atlas--post-sync
                     "TAGS" (car val))
                   ,@(mapcar (lambda (v)
                               (apply-partially
                                #'my/manifolding-atlas--ensure-ref-note
                                'tags v))
                             val)))))

(defun my/manifolding-atlas-org-prompt--fragment-tagopt (key plist val)
  (let ((sentinel (or (plist-get plist :default) "auto")))
    (when (and val (not (string-equal val sentinel)))
      `(:tags (,val)
        :post-apply (,(apply-partially
                       #'my/manifolding-atlas--ensure-ref-note
                       (intern (downcase
                                (or (plist-get plist :live) key)))
                       val))))))

(defun my/manifolding-atlas-org-prompt--fragment-template (val)
  (let ((v (or val "WARNING")))
    `(:properties (("TEMPLATE" . ,v))
      :post-apply (,(apply-partially
                     #'my/manifolding-atlas-prompt-template--apply
                     v)))))

(defun my/manifolding-atlas-org-prompt--fragment-mastering (key val)
  (cond
   ((or (null val) (string-equal val "WARNING"))
    `(:properties ((,key . "WARNING"))))
   ((string-equal val "SUSPEND")
    `(:properties ((,key . "SUSPEND"))
      :post-apply (,(apply-partially
                     #'my/manifolding-atlas-mastering--init-schedule t))))
   (t
    `(:properties ((,key . ,val))
      :post-apply (,(apply-partially
                     #'my/manifolding-atlas-mastering--init-schedule nil))))))

(defun my/manifolding-atlas-org-prompt--fragment-scoped (key plist val)
  (when (and val (not (string-equal val "WARNING")))
    `(:properties ((,key . ,val))
      :post-apply (,(apply-partially
                     #'my/manifolding-atlas--apply-scoped-post
                     (intern (downcase
                              (or (plist-get plist :live) key)))
                     key val)))))

(defun my/manifolding-atlas-org-prompt--fragment-multi (key val)
  (when val
    `(:properties ((,key . ,val)))))

(defun my/manifolding-atlas-org-prompt--fragment-mindmap (key val)
  (if (and val (plistp val))
      (let ((placement (plist-get val :placement))
            (target-id (plist-get val :target-id)))
        (if (string= placement "root")
            `(:properties ((,key . "WARNING")))
          (let ((link (my/manifolding-atlas--ensure-ref-note
                       'mm-placement placement)))
            `(:properties ((,key . ,(or link placement)))
              :post-apply (,(apply-partially
                             #'mm/--apply-placement
                             placement target-id))))))
    `(:properties ((,key . "WARNING")))))

(defun my/manifolding-atlas-org-prompt--fragment-live (key plist val)
  (let ((family (intern
                 (downcase
                  (or (plist-get plist :live)
                      (replace-regexp-in-string "_" "-" key))))))
    (if (or (null val) (string-equal val "WARNING"))
        `(:properties ((,key . "WARNING"))
          :post-apply (,(apply-partially
                         #'my/manifolding-atlas--clear-state-transcribes
                         family)))
      (let* ((link (my/manifolding-atlas--ensure-ref-note family val))
             (ref-id (my/manifolding-atlas--id-from-link link)))
        `(:post-apply (,(apply-partially
                         #'my/manifolding-atlas--apply-state-post
                         family val ref-id)))))))

(defun my/manifolding-atlas-org-prompt--fragment (key kind plist val)
  (pcase kind
    ('todo (my/manifolding-atlas-org-prompt--fragment-todo val))
    ('tags (my/manifolding-atlas-org-prompt--fragment-tags val))
    ('tagopt (my/manifolding-atlas-org-prompt--fragment-tagopt
              key plist val))
    ('mastering (my/manifolding-atlas-org-prompt--fragment-mastering
                 key val))
    ('scoped (my/manifolding-atlas-org-prompt--fragment-scoped
              key plist val))
    ('template (my/manifolding-atlas-org-prompt--fragment-template val))
    ('multi (my/manifolding-atlas-org-prompt--fragment-multi key val))
    ('mindmap (my/manifolding-atlas-org-prompt--fragment-mindmap
               key val))
    ('live (my/manifolding-atlas-org-prompt--fragment-live
            key plist val))
    (_
     (when val
       `(:properties ((,key . ,val)))))))

(defvar my/manifolding-atlas-org-prompt--boot-timer nil)

(with-eval-after-load 'manifolding-atlas
  (when my/manifolding-atlas-org-prompt--boot-timer
    (cancel-timer my/manifolding-atlas-org-prompt--boot-timer))
  (setq my/manifolding-atlas-org-prompt--boot-timer
        (run-with-idle-timer
   0 nil
   (lambda ()
     (condition-case err
         (let ((n (my/manifolding-atlas-org-prompt--register-all)))
           (message "org-prompts: registered %d declarative prompts" n)
           (when (= n 0)
             (lwarn 'manifolding-atlas-org-prompts
                    :warning "registered 0 declarative prompts")))
       (error (lwarn 'manifolding-atlas-org-prompts :error
                     "registration failed: %s" err)))))))

(defvar my/manifolding-atlas-prompt-help-map
  '((scheduled . "schedule.org")
    (deadline  . "schedule.org"))
  "Alist mapping prompt :name to help filename.
Entries here override the default <name>.org.")

(defun my/manifolding-atlas--help-file (name)
  "Return the help filename for prompt NAME."
  (or (alist-get name my/manifolding-atlas-prompt-help-map)
      (format "%s.org" name)))

(defvar my/manifolding-atlas--help-opened nil
  "Non-nil when a help buffer was opened for the current prompt.")

(defvar my/manifolding-atlas--help-buffer nil
  "The help buffer opened by `my/manifolding-atlas--show-help'.")

(defvar my/manifolding-atlas--help-window-config nil
  "Window configuration captured before showing help.")

(defun my/manifolding-atlas--show-help (name)
  "Open prompt NAME's help file full-screen with org-tree-slide.
Search recursively under blueprints/ for the file."
  (let* ((file (my/manifolding-atlas--help-file name))
          (properties-dir (expand-file-name "Manifolding-Emacs/modules/manifolding-atlas/blueprints/"
                                            user-emacs-directory))
         (path (car (file-expand-wildcards
                     (concat properties-dir "**/" file) t))))
    (when (and path (file-exists-p path))
      (setq my/manifolding-atlas--help-opened t
            my/manifolding-atlas--help-window-config
            (current-window-configuration))
      (delete-other-windows)
      (setq my/manifolding-atlas--help-buffer (find-file path))
      (goto-char (point-min))
      (org-tree-slide-mode 1))))

(defun my/manifolding-atlas--close-help ()
  "Close the help view and restore the pre-help window layout."
  (when my/manifolding-atlas--help-opened
    (setq my/manifolding-atlas--help-opened nil)
    (when (buffer-live-p my/manifolding-atlas--help-buffer)
      (with-current-buffer my/manifolding-atlas--help-buffer
        (when (bound-and-true-p org-tree-slide-mode)
          (org-tree-slide-mode -1))
        (kill-buffer)))
    (setq my/manifolding-atlas--help-buffer nil)
    (when my/manifolding-atlas--help-window-config
      (ignore-errors
        (set-window-configuration my/manifolding-atlas--help-window-config))
      (setq my/manifolding-atlas--help-window-config nil))))

(defvar my/manifolding-atlas--creation-todo nil
  "TODO value for the current note creation.
Set by `my/manifolding-atlas-collect-prompts', read by the heading-format
advice on `manifolding-atlas--format-note-content'.")

(defvar my/manifolding-atlas-collect-defer nil
  "When non-nil, buffer-UI declarative prompts are deferred into an
async session instead of blocking during collection.")

(defvar my/manifolding-atlas-org-prompt--defaults-only nil
  "Bound non-nil by fast collection: no interaction, nothing deferred.")

(defun my/manifolding-atlas-collect--merge-list-channels (result frag)
  "Append FRAG's :tags and :post-apply onto RESULT."
  (when-let ((v (plist-get frag :tags)))
    (setq result (plist-put result :tags
                            (append (plist-get result :tags) v))))
  (when-let ((v (plist-get frag :post-apply)))
    (setq result (plist-put result :post-apply
                            (append (plist-get result :post-apply) v))))
  result)

(defun my/manifolding-atlas-collect--merge-fragment (result frag)
  "Merge FRAG into accumulating RESULT per the collector's channels."
  (setq result (my/manifolding-atlas-collect--merge-list-channels
                result frag))
  (when-let ((v (plist-get frag :properties)))
    (setq result (plist-put result :properties
                            (append (plist-get result :properties)
                                    (cl-remove-if (lambda (p) (or (null (cdr p))
                                                                  (string-empty-p (cdr p))))
                                                  v)))))
  (when-let ((v (plist-get frag :body)))
    (setq result (plist-put result :body
                            (concat (or (plist-get result :body) "") v))))
  (when-let ((v (plist-get frag :after)))
    (setq result (plist-put result :after v)))
  (when-let ((v (plist-get frag :file-name)))
    (setq result (plist-put result :file-name v)))
  (when (plist-member frag :todo)
    (setq result (plist-put result :todo (plist-get frag :todo)))
    (let ((tv (plist-get frag :todo)))
      (when (and tv (not (string-empty-p tv))
             (not (string-equal tv "WARNING")))
        (setq my/manifolding-atlas--creation-todo tv))))
  result)

(defvar my/manifolding-atlas-org-prompt--custom-set nil)

(defun my/manifolding-atlas-collect--dspec-for (key)
  "Return the declarative spec behind registry KEY, or nil."
  (and (fboundp 'my/manifolding-atlas-org-prompt--declarative-p)
       (my/manifolding-atlas-org-prompt--declarative-p key)
       (fboundp 'my/manifolding-atlas-org-prompt--base-key)
       (boundp 'my/manifolding-atlas-org-prompt--specs)
       (gethash (my/manifolding-atlas-org-prompt--base-key key)
                my/manifolding-atlas-org-prompt--specs)))

(defun my/manifolding-atlas-collect--defer-p (dspec)
  "Non-nil when declarative DSPEC should queue for the async session."
  (and dspec
       my/manifolding-atlas-collect-defer
       (not my/manifolding-atlas-org-prompt--defaults-only)
       (bound-and-true-p my/manifolding-atlas-org-prompt-ui)
       (eq my/manifolding-atlas-org-prompt-ui 'buffer)
       (memq (plist-get dspec :kind)
             '(property live todo multi tagopt
               scoped mastering mindmap))
       (file-exists-p (plist-get dspec :file))))

(defun my/manifolding-atlas-collect--queue-deferred (key dspec deferred-list)
  "Queue KEY's DSPEC for the async session; return new DEFERRED-LIST."
  (cons (list :spec dspec
              :default (if (eq key
                               (my/manifolding-atlas-org-prompt--base-key key))
                           nil
                         (plist-get dspec :task-default)))
        deferred-list))

(defun my/manifolding-atlas-collect--silent-fragment (dspec)
  "Return the skip fragment for declarative DSPEC."
  (let ((skip-val (pcase (plist-get dspec :kind)
                    ((or 'tags 'multi) nil)
                    (_ "WARNING"))))
    (my/manifolding-atlas-org-prompt--fragment
     (plist-get dspec :key)
     (plist-get dspec :kind)
     (plist-get dspec :plist)
     skip-val)))

(defun my/manifolding-atlas-collect--run-interactive (spec context declared)
  "Run SPEC's prompt against CONTEXT; DECLARED suppresses help."
  (unless declared
    (my/manifolding-atlas--show-help (plist-get spec :name)))
  (unwind-protect
      (funcall (plist-get spec :to-plist)
               (funcall (plist-get spec :prompt-fn))
               context)
    (unless declared
      (my/manifolding-atlas--close-help))))

(defun my/manifolding-atlas--fast-read-string (prompt &optional initial-input history default-value _inherit)
  "Return DEFAULT-VALUE or INITIAL-INPUT or empty — no prompt."
  (or default-value initial-input ""))

(defun my/manifolding-atlas--fast-completing-read (prompt collection &optional predicate _require-match initial-input history default-value _inherit)
  "Return DEFAULT-VALUE or first candidate."
  (or default-value
      (if (and collection (not (functionp collection))) (car collection) "")
      ""))

(defun my/manifolding-atlas--fast-read-char-choice (prompt chars &optional _inhibit-keyboard-quit)
  "Return \\r or first char — maps to skip/default in all prompt functions."
  (if (memq ?\r chars) ?\r (car chars)))

(defun my/manifolding-atlas--collect-default-prompts (context &rest extra-contexts)
  "Like `my/manifolding-atlas-collect-prompts' but all prompts return defaults.
Temporarily overrides `read-string', `completing-read' and
`read-char-choice' to return their default/skip values."
  (cl-letf (((symbol-function 'read-string) #'my/manifolding-atlas--fast-read-string)
            ((symbol-function 'completing-read) #'my/manifolding-atlas--fast-completing-read)
            ((symbol-function 'read-char-choice) #'my/manifolding-atlas--fast-read-char-choice)
            (my/manifolding-atlas-org-prompt--defaults-only t))
    (apply #'my/manifolding-atlas-collect-prompts context extra-contexts)))

(defun my/manifolding-atlas-collect--selection-fast-level (specialized-contexts general-contexts)
  "Return effective level (1 = interactive property selection)."
  (setq my/manifolding-atlas-org-prompt--custom-set t)
  1)

(defun my/manifolding-atlas--dedupe-properties (props)
  "Drop later PROPS pairs whose KEY already appeared."
  (let (seen out)
    (dolist (pair props (nreverse out))
      (let ((key (car pair)))
        (unless (member key seen)
          (push key seen)
          (push pair out))))))

(defun my/manifolding-atlas--fast-level ()
  "Compatibility stub: capture speed is always custom -- the property
grid asks directly, no separate fast/slow menu. Keeps historical call
sites (this numeric contract) working now that the speed menu is gone."
  4)

(defun my/manifolding-atlas-collect-prompts-with-fast (specialized-contexts general-contexts &optional fast-level)
  "Collect prompts using fast mode levels."
  (setq my/manifolding-atlas-org-prompt--deferred nil)
  (let* ((fast0 (or fast-level (my/manifolding-atlas--fast-level)))
         (fast (if (= fast0 4)
                   (my/manifolding-atlas-collect--selection-fast-level
                    specialized-contexts general-contexts)
                 fast0))
         (my/manifolding-atlas-collect-defer t)
         (spec (cond
                ((and (= fast 1) my/manifolding-atlas-org-prompt--custom-set)
                 (my/manifolding-atlas-collect-prompts specialized-contexts))
                ((>= fast 2)
                 (my/manifolding-atlas--collect-default-prompts specialized-contexts))
                (t
                 (my/manifolding-atlas-collect-prompts specialized-contexts))))
         (gen  (cond
                ((= fast 0)
                 (my/manifolding-atlas-collect-prompts general-contexts))
                (my/manifolding-atlas-org-prompt--custom-set
                 (my/manifolding-atlas-collect-prompts general-contexts))
                (t
                 (my/manifolding-atlas--collect-default-prompts general-contexts)))))
    (let ((merged (list :tags (delete-dups (append (plist-get gen :tags)
                                                   (plist-get spec :tags)))
                    :properties (my/manifolding-atlas--dedupe-properties
                                 (append (plist-get gen :properties)
                                         (plist-get spec :properties)))
                    :body (concat (plist-get gen :body) (plist-get spec :body))
                    :post-apply (append (plist-get gen :post-apply) (plist-get spec :post-apply)))))
      (setq my/manifolding-atlas-org-prompt--custom-set nil)
      merged)))

(defvar my/manifolding-atlas-missing--file "admin/MISSING PROMPTS"
  "Filename for tracking notes with WARNING state properties.")
(setq my/manifolding-atlas-missing--file "admin/MISSING PROMPTS")

(defun my/manifolding-atlas-missing--path ()
  "Return full path to MISSING PROMPTS."
  (expand-file-name my/manifolding-atlas-missing--file
                    (my/manifolding-atlas-root-dir)))

(defun my/manifolding-atlas-missing--ensure-file ()
  "Create MISSING PROMPTS if it does not exist."
  (let ((path (my/manifolding-atlas-missing--path)))
    (make-directory (file-name-directory path) t)
    (unless (file-exists-p path)
      (with-temp-file path
        (insert "#+TITLE: MISSING PROMPTS\n")
        (insert "#+AUTHOR: Shape\n")
        (insert "#+DESCRIPTION: Auto-generated - notes with unanswered state prompts.\n")
        (insert "#+STARTUP: overview\n\n")))
    path))

(defun my/manifolding-atlas-missing--aggregate-health ()
  "Return violation entries aggregated by note id."
  (let ((by-id (make-hash-table :test #'equal)))
    (dolist (health (manifolding-atlas-blueprint-collection-health))
      (let ((schema-name (manifolding-atlas-blueprint-health-schema health)))
        (dolist (pair (manifolding-atlas-blueprint-health-invalid-notes health))
          (let* ((note (car pair))
                 (violations (cdr pair))
                 (id (manifolding-atlas-note-id note))
                 (title (manifolding-atlas-note-title note))
                 (existing (gethash id by-id)))
            (if existing
                (progn
                  (plist-put existing :schemas
                             (cons (symbol-name schema-name)
                                   (plist-get existing :schemas)))
                  (plist-put existing :violations
                             (append violations (plist-get existing :violations))))
              (puthash id
                       (list :id id :title title
                             :schemas (list (symbol-name schema-name))
                             :violations violations)
                       by-id))))))
    (let (entries)
      (maphash (lambda (_id plist) (push plist entries)) by-id)
      (nreverse entries))))

(defun my/manifolding-atlas-missing--write-entries (path entries)
  "Write ENTRIES as TODO headings to PATH; delete the file when empty."
  (if entries
      (with-temp-file path
        (insert "#+TITLE: MISSING PROMPTS\n")
        (insert "#+AUTHOR: Shape\n")
        (insert "#+DESCRIPTION: Auto-generated - notes with schema violations.\n")
        (insert "#+STARTUP: overview\n\n")
        (dolist (entry entries)
          (insert (format "* TODO [[id:%s][%s]]\n"
                          (plist-get entry :id)
                          (plist-get entry :title)))
          (insert "  :PROPERTIES:\n")
          (insert (format "  :CREATED:       %s\n"
                          (format-time-string "<%Y-%m-%d %a>")))
          (insert (format "  :SCHEMAS:       %s\n"
                          (string-join (plist-get entry :schemas) ", ")))
          (let ((vs (plist-get entry :violations)))
            (when vs
              (insert (format "  :VIOLATIONS:    %s\n"
                              (string-join
                               (mapcar #'manifolding-atlas-violation-message vs)
                               "; ")))))
          (insert "  :END:\n\n")))
    (when (file-exists-p path)
      (delete-file path))))

(defun my/manifolding-atlas-missing--rebuild-from-health ()
  "Rebuild MISSING PROMPTS from schema health data."
  (interactive)
  (let ((path (my/manifolding-atlas-missing--path)))
    (make-directory (file-name-directory path) t)
    (my/manifolding-atlas-missing--write-entries
     path (my/manifolding-atlas-missing--aggregate-health))))

(defun my/manifolding-atlas--post-sync (_property _value _note)
  "No-op.  Schema health replaces per-property MISSING PROMPTS sync."
  nil)

(add-hook 'org-capture-after-finalize-hook #'my/manifolding-atlas-missing--rebuild-from-health)

(defvar my/manifolding-atlas-missing--startup-timer nil
  "Timer handle for retrying startup rebuild until DB is ready.")

(defun my/manifolding-atlas-missing--startup-rebuild ()
  "Run rebuild-from-health if manifolding-atlas DB has notes; retry later if not."
  (condition-case nil
      (if (> (length (manifolding-atlas-db-query)) 0)
          (progn
            (my/manifolding-atlas-missing--rebuild-from-health)
            (when my/manifolding-atlas-missing--startup-timer
              (cancel-timer my/manifolding-atlas-missing--startup-timer)
              (setq my/manifolding-atlas-missing--startup-timer nil)))
        (setq my/manifolding-atlas-missing--startup-timer
              (run-with-idle-timer 5 nil #'my/manifolding-atlas-missing--startup-rebuild)))
    (error
     (setq my/manifolding-atlas-missing--startup-timer
           (run-with-idle-timer 5 nil #'my/manifolding-atlas-missing--startup-rebuild)))))

;; Disabled: `manifolding-atlas-db-query' in a startup retry loop triggers
;; recursive sqlite3_step CPU spike on daemon start.
;;(my/manifolding-atlas-missing--startup-rebuild)

(defvar my/manifolding-atlas--pending-post-apply nil
  "Post-apply functions for current note creation.
Set by `my/manifolding-atlas--default-create-fn', consumed by the capture functions.")

#+begin_src emacs-lisp
;;; manifolding-atlas-buffer.el --- Buffer related utilities -*- lexical-binding: t; -*-
;;
;; Copyright (c) 2015-2026 Boris Buliga <boris@d12frosted.io>
;;
;; Author: Boris Buliga <boris@d12frosted.io>
;; Maintainer: Boris Buliga <boris@d12frosted.io>
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see
;; <http://www.gnu.org/licenses/>.
;;
;; Created: 13 May 2021
;;
;; URL: https://github.com/d12frosted/vulpea
;;
;; License: GPLv3
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Various utilities to modify `org-mode' buffer, namely properties
;; and metadata.
;;
;; Properties are buffer-wide key-values defined as #+KEY: VALUE in
;; the header of file.
;;
;; Metadata is defined by the first description list in the file, e.g.
;; list like:
;;
;; - key1 :: value1
;; - key2 :: value21
;; - key2 :: value22
;; - key3 :: value3
;;
;;; Code:

(require 'dash)
(require 'org-element)
(require 'seq)

(declare-function manifolding-atlas-db-query-tags "manifolding-atlas-db-query")
(require 's)

(require 'url-parse)

;;; Customization

(defcustom manifolding-atlas-buffer-alias-property "ALIASES"
  "Property name for note aliases.

You can change this to any property name you prefer, such as
\"ROAM_ALIASES\" for org-roam compatibility."
  :type 'string
  :group 'manifolding-atlas)

(defcustom manifolding-atlas-buffer-meta-change-functions nil
  "Abnormal hook run when buffer metadata changes.

Each function is called with three arguments: PROP, OLD and NEW.
PROP is the affected metadata property name (a string).  OLD and
NEW are the lists of its string values before and after the
change.  Adding a property yields an empty OLD; removing one
yields an empty NEW.

The hook fires once per affected property, in the buffer that was
modified, and only for actual changes (when OLD and NEW differ).
It reports the outermost public operation only: the nested
mutations performed by `manifolding-atlas-buffer-meta-set' and
`manifolding-atlas-buffer-meta-sort' do not produce extra events, and a
reorder via `manifolding-atlas-buffer-meta-sort' produces none at all.

OLD and NEW are computed only while this hook is non-nil, so an
empty hook adds no overhead.  Handlers run with re-entrant
notification inhibited, so a handler that itself mutates metadata
does not trigger the hook recursively."
  :type 'hook
  :group 'manifolding-atlas)

(defun manifolding-atlas-buffer-title-get ()
  "Get TITLE in current buffer."
  (manifolding-atlas-buffer-prop-get "title"))

(defun manifolding-atlas-buffer-title-set (title)
  "Set TITLE in current buffer.

If the title is already set, replace its value."
  (manifolding-atlas-buffer-prop-set "title" title))

(defun manifolding-atlas-buffer-tags-get (&optional local)
  "Return tags for the note at point.

At file level (outline-level 0), returns filetags.
At heading level, returns all applicable tags including those
inherited from the file and parent headings, respecting
`org-use-tag-inheritance'.  When LOCAL is non-nil, returns only
the heading's own tags without inheritance."
  (if (= (org-outline-level) 0)
      (seq-uniq
       (cl-mapcan (lambda (v) (split-string v "[ :]" t))
                  (manifolding-atlas-buffer-prop-get-all "filetags")))
    (mapcar #'substring-no-properties
            (org-get-tags nil local))))

(defun manifolding-atlas-buffer-tags-set (&rest tags)
  "Set TAGS for the note at point.

At file level (outline-level 0), sets filetags.
At heading level, sets heading tags.
Duplicate tags are automatically removed."
  (let ((tags (seq-uniq tags)))
    (if (= (org-outline-level) 0)
        (progn
          ;; Remove all #+filetags: lines first to consolidate
          (manifolding-atlas-buffer-prop-remove-all "filetags")
          (when tags
            (manifolding-atlas-buffer-prop-set
             "filetags" (concat ":" (string-join tags ":") ":"))))
      (save-excursion
        (org-back-to-heading t)
        (org-set-tags tags)))))

(defun manifolding-atlas-buffer-tags-add (&optional tags)
  "Add TAGS to the note at point.

At file level (outline-level 0), modifies filetags.
At heading level, modifies heading tags.

When called interactively, prompt for tags to add with completion
from existing tags in the database."
  (interactive
   (list (completing-read-multiple
          "Tag: "
          (ignore-errors (manifolding-atlas-db-query-tags)))))
  (let* ((tags (if (listp tags) tags (list tags)))
         (current-tags (manifolding-atlas-buffer-tags-get t))
         (new-tags (append current-tags tags)))
    (apply #'manifolding-atlas-buffer-tags-set new-tags)))

(defun manifolding-atlas-buffer-tags-remove (&optional tags)
  "Remove TAGS from the note at point.

At file level (outline-level 0), modifies filetags.
At heading level, modifies heading tags.

When called interactively, prompt for tags to remove from current tags."
  (interactive)
  (let* ((current-tags (manifolding-atlas-buffer-tags-get t)))
    (unless current-tags
      (user-error
       (if (and (> (org-outline-level) 0) (manifolding-atlas-buffer-tags-get))
           "No local tags to remove (note has inherited tags only)"
         "No tags to remove")))
    (let* ((tags (or (if (listp tags) tags (list tags))
                     (completing-read-multiple "Remove tag: " current-tags)))
           (new-tags (seq-difference current-tags tags #'string-equal)))
      (apply #'manifolding-atlas-buffer-tags-set new-tags))))

(defun manifolding-atlas-buffer-alias-get ()
  "Get list of aliases for the note at point.

Returns list of alias strings from the property defined by
`manifolding-atlas-buffer-alias-property'. Handles both quoted aliases (with spaces)
and unquoted aliases properly."
  (when-let* ((aliases-str (org-entry-get nil manifolding-atlas-buffer-alias-property)))
    (setq aliases-str (string-trim aliases-str))
    (let ((result nil)
          (pos 0))
      (while (< pos (length aliases-str))
        (let ((char (aref aliases-str pos)))
          (cond
           ;; Skip whitespace
           ((= char ?\s)
            (setq pos (1+ pos)))
           ;; Quoted alias - find closing quote
           ((= char ?\")
            (let ((end (string-match "\"" aliases-str (1+ pos))))
              (if end
                  (progn
                    (push (substring aliases-str (1+ pos) end) result)
                    (setq pos (1+ end)))
                (error "Unmatched quote in %s" manifolding-atlas-buffer-alias-property))))
           ;; Unquoted alias - find next space or end of string
           (t
            (let ((end (or (string-match " " aliases-str pos)
                           (length aliases-str))))
(push (substring aliases-str pos end) result)
              (setq pos end))))
      (nreverse result)))

(defun manifolding-atlas-buffer-alias-add (alias)
  "Add ALIAS to the note at point.

ALIAS is added to the property defined by `manifolding-atlas-buffer-alias-property'.
If ALIAS contains spaces, it will be quoted automatically."
  (interactive "sAlias: ")
  (let* ((aliases (manifolding-atlas-buffer-alias-get))
         (alias (string-trim alias)))
    (unless (member alias aliases)
      (setq aliases (append aliases (list alias)))
      ;; Format aliases: quote ones with spaces, leave others unquoted
      (let ((formatted-aliases
             (mapcar (lambda (a)
                       (if (string-match-p " " a)
                           (format "\"%s\"" a)
                         a))
                     aliases)))
        (org-entry-put nil manifolding-atlas-buffer-alias-property (string-join formatted-aliases " "))))))

(defun manifolding-atlas-buffer-alias-set (&rest aliases)
  "Set ALIASES for the note at point, replacing any existing aliases.

ALIASES is a list of alias strings. If empty, removes the alias property.
Aliases containing spaces will be quoted automatically."
  (if aliases
      (let ((formatted-aliases
             (mapcar (lambda (a)
                       (if (string-match-p " " a)
                           (format "\"%s\"" a)
                         a))
                     aliases)))
        (org-entry-put nil manifolding-atlas-buffer-alias-property (string-join formatted-aliases " ")))
    (org-entry-delete nil manifolding-atlas-buffer-alias-property)))

(defun manifolding-atlas-buffer-alias-remove (&optional alias)
  "Remove ALIAS from the note at point.

If ALIAS is nil, prompt for an alias to remove from available aliases."
  (interactive)
  (let* ((aliases (manifolding-atlas-buffer-alias-get)))
    (when aliases
      (let* ((alias (or alias
                        (completing-read "Remove alias: " aliases nil t)))
             (aliases (delete alias aliases)))
        (if aliases
            ;; Format aliases: quote ones with spaces, leave others unquoted
            (let ((formatted-aliases
                   (mapcar (lambda (a)
                             (if (string-match-p " " a)
                                 (format "\"%s\"" a)
                               a))
                           aliases)))
              (org-entry-put nil manifolding-atlas-buffer-alias-property (string-join formatted-aliases " ")))
          ;; No aliases left, remove the property entirely
          (org-entry-delete nil manifolding-atlas-buffer-alias-property))))))

(defun manifolding-atlas-buffer-prop-set (name value)
  "Set a file property called NAME to VALUE in buffer file.

If the property is already set, replace its value.  A matching line
inside a verbatim block (source, example, export, comment) is block
content rather than a real keyword: it is left untouched, and when
only such lines exist a fresh property line is inserted."
  (setq name (downcase name))
  (org-with-point-at 1
    (let ((case-fold-search t)
          (regexp (concat "^#\\+" name ":\\(.*\\)"))
          replaced)
      (while (and (not replaced)
                  (re-search-forward regexp (point-max) t))
        (unless (manifolding-atlas-buffer--point-in-raw-block-p (match-beginning 0))
          ;; LITERAL (3rd arg) so backslashes in VALUE are inserted
          ;; verbatim rather than interpreted as backreferences.
          (replace-match (concat "#+" name ": " value) 'fixedcase t)
          (setq replaced t)))
      (unless replaced
        (goto-char (point-min))
        (while (and (not (eobp))
                    (looking-at "^[#:]"))
          (if (save-excursion (end-of-line) (eobp))
              (progn
                (end-of-line)
                (insert "\n"))
            (forward-line)
            (beginning-of-line)))
        (insert "#+" name ": " value "\n")))))

(defun manifolding-atlas-buffer-prop-set-list (name values &optional separators)
  "Set a file property called NAME to VALUES in current buffer.

VALUES are quoted and combined into single string using
`combine-and-quote-strings'.

If SEPARATORS is non-nil, it should be a regular expression
matching text that separates, but is not part of, the substrings.
If nil it defaults to `split-string-default-separators', normally
\"[ \\f\\t\\n\\r\\v]+\", and OMIT-NULLS is forced to t.

If the property is already set, replace its value."
  (manifolding-atlas-buffer-prop-set
   name (combine-and-quote-strings values separators)))

(defun manifolding-atlas-buffer--point-in-raw-block-p (&optional pos)
  "Return non-nil when POS (or point) sits inside a verbatim block.

Source, example, export, and comment blocks hold raw text, so a
line that looks like #+KEYWORD: inside them is block content, not a
real document keyword.  The property readers and writers consult
this to skip such quoted markup (e.g. a note that embeds Org
examples).

POS defaults to point.  Preserves the caller's point and match
data."
  (save-match-data
    (let ((element (save-excursion
                     (when pos (goto-char pos))
                     (beginning-of-line)
                     (org-element-at-point))))
      (memq (org-element-type element)
            '(src-block example-block export-block comment-block)))))

(defun manifolding-atlas-buffer-prop-get (name)
  "Get a buffer property called NAME as a string.

A line matching #+NAME: that lives inside a verbatim block (source,
example, export, comment) is ignored, since it is block content
rather than a real document keyword."
  (org-with-point-at 1
    ;; Bind `case-fold-search' (like the sibling readers) so the property
    ;; is found regardless of the caller's setting, and quote NAME so a
    ;; regexp-special character in it is matched literally.
    (let ((case-fold-search t)
          (regexp (concat "^#\\+" (regexp-quote name) ": \\(.*\\)"))
          result done)
      (while (and (not done)
                  (re-search-forward regexp (point-max) t))
        (unless (manifolding-atlas-buffer--point-in-raw-block-p)
          ;; First genuine keyword wins, matching the historical
          ;; first-match-or-nil behaviour.
          (setq done t)
          (let ((value (string-trim
                        (buffer-substring-no-properties
                         (match-beginning 1)
                         (match-end 1)))))
            (unless (string-empty-p value)
              (setq result value)))))
      result)))

(defun manifolding-atlas-buffer-prop-get-all (name)
  "Get all values of buffer property called NAME as a list of strings.

Unlike `manifolding-atlas-buffer-prop-get' which returns only the first
match, this collects values from all lines matching #+NAME:.
Lines inside verbatim blocks (source, example, export, comment)
are ignored, since they are block content rather than real
document keywords."
  (let (values)
    (org-with-point-at 1
      (let ((case-fold-search t))
        (while (re-search-forward (concat "^#\\+" name ": \\(.*\\)")
                                  (point-max) t)
          (unless (manifolding-atlas-buffer--point-in-raw-block-p)
            (let ((value (string-trim
                          (buffer-substring-no-properties
                           (match-beginning 1)
                           (match-end 1)))))
              (unless (string-empty-p value)
                (push value values)))))))
    (nreverse values)))

(defun manifolding-atlas-buffer-prop-get-list (name &optional separators)
  "Get a buffer property NAME as a list using SEPARATORS.

If SEPARATORS is non-nil, it should be a regular expression
matching text that separates, but is not part of, the substrings.
If nil it defaults to `split-string-default-separators', normally
\"[ \\f\\t\\n\\r\\v]+\", and OMIT-NULLS is forced to t."
  (let ((value (manifolding-atlas-buffer-prop-get name)))
    (when value
      (split-string-and-unquote value separators))))

(defun manifolding-atlas-buffer-prop-remove (name)
  "Remove a buffer property called NAME.

A matching line inside a verbatim block (source, example, export,
comment) is block content rather than a real keyword and is left
untouched."
  (org-with-point-at 1
    (let ((case-fold-search t)
          (regexp (concat "^#\\+" name ":.*\n?"))
          done)
      (while (and (not done)
                  (re-search-forward regexp (point-max) t))
        (unless (manifolding-atlas-buffer--point-in-raw-block-p (match-beginning 0))
          (replace-match "")
          (setq done t))))))

(defun manifolding-atlas-buffer-prop-remove-all (name)
  "Remove all buffer properties called NAME.

Matching lines inside verbatim blocks (source, example, export,
comment) are block content rather than real keywords and are left
untouched."
  (org-with-point-at 1
    (let ((case-fold-search t)
          (regexp (concat "^#\\+" name ":.*\n?")))
      (while (re-search-forward regexp (point-max) t)
        (unless (manifolding-atlas-buffer--point-in-raw-block-p (match-beginning 0))
          (replace-match ""))))))

(defvar manifolding-atlas-buffer-meta--inhibit-change nil
  "When non-nil, suppress `manifolding-atlas-buffer-meta-change-functions'.

Bound to t while a higher-level metadata operation performs nested
mutations, so the change hook fires once for the outermost call.")

(defun manifolding-atlas-buffer-meta--notify-p ()
  "Return non-nil when a metadata change should be reported."
  (and manifolding-atlas-buffer-meta-change-functions
       (not manifolding-atlas-buffer-meta--inhibit-change)))

(defun manifolding-atlas-buffer-meta--notify (prop old new)
  "Report a metadata change of PROP from OLD to NEW.

OLD and NEW are lists of string values.  Does nothing when they
are equal.  Re-entrant notification is inhibited while the hook
runs."
  (unless (equal old new)
    (let ((manifolding-atlas-buffer-meta--inhibit-change t))
      (run-hook-with-args 'manifolding-atlas-buffer-meta-change-functions prop old new))))

(defun manifolding-atlas-buffer-meta (&optional bound)
  "Get metadata from the current buffer.

Return plist (:file :buffer :pl :bound)

BOUND controls the scope of metadata extraction:
- nil or \\='buffer: search the entire buffer (legacy behavior)
- \\='heading: if point is in a heading, scope to that subtree;
  otherwise scope to content before first heading
- A position (number): scope to the subtree at that position

Metadata is defined by the first description list in the scope,
e.g. list like:

- key1 :: value1
- key2 :: value21
- key2 :: value22
- key3 :: value3

In most cases, it's better to use either `manifolding-atlas-buffer-meta-get'
to retrieve a single value for a given key or
`manifolding-atlas-buffer-meta-get-list' to retrieve all values for a given
key.

In case you are doing multiple calls to meta API, it's better to
get metadata using this function and use bang version of
functions, e.g. `manifolding-atlas-buffer-meta-get!'."
  (let* ((file (buffer-file-name (current-buffer)))
         (buf (org-element-parse-buffer))
         ;; Determine the element to search within
         (scope-element
          (cond
           ;; No bound or 'buffer - search whole buffer
           ((or (null bound) (eq bound 'buffer))
            buf)
           ;; 'heading - auto-detect based on current position
           ((eq bound 'heading)
            (save-excursion
              (if (org-before-first-heading-p)
                  ;; Before first heading - get file-level section
                  (manifolding-atlas-buffer-meta--file-level-section buf)
                ;; At or after a heading - find the section within the headline
                (org-back-to-heading-or-point-min t)
                (let ((heading-pos (point)))
                  (manifolding-atlas-buffer-meta--heading-section buf heading-pos)))))
           ;; Position - find heading at that position
           ((numberp bound)
            (save-excursion
              (goto-char bound)
              (if (org-before-first-heading-p)
                  (manifolding-atlas-buffer-meta--file-level-section buf)
                (org-back-to-heading-or-point-min t)
                (let ((heading-pos (point)))
                  (manifolding-atlas-buffer-meta--heading-section buf heading-pos)))))
           (t buf)))
         ;; Find the first descriptive list, stopping at headlines
         (pls (org-element-map scope-element 'plain-list #'identity nil nil 'headline))
         (pl (seq-find
              (lambda (pl)
                (equal 'descriptive
                       (org-element-property :type pl)))
              pls)))
    (list :file file
          :buffer buf
          :pl pl
          :bound bound)))

(defun manifolding-atlas-buffer-meta--file-level-section (buf)
  "Get the file-level section from parsed buffer BUF.
Returns the section element before any headlines, or nil if none exists."
  ;; The file-level section is a direct child of org-data, before any headline
  (let ((children (org-element-contents buf)))
    (cl-find-if
     (lambda (el)
       (eq (org-element-type el) 'section))
     children)))

(defun manifolding-atlas-buffer-meta--heading-section (buf heading-pos)
  "Get the section element from the heading at HEADING-POS in BUF.
Returns the section child of the headline, which contains the
metadata but not nested subheadings."
  (let ((heading-el (org-element-map buf 'headline
                      (lambda (hl)
                        (when (= (org-element-property :begin hl) heading-pos)
                          hl))
                      nil t)))
    (when heading-el
      ;; Get the first section child of the headline
      (cl-find-if
       (lambda (el)
         (eq (org-element-type el) 'section))
       (org-element-contents heading-el)))))

(defun manifolding-atlas-buffer-meta-props (&optional meta)
  "Return list of all props from META."
  (let* ((meta (or meta (manifolding-atlas-buffer-meta)))
         (pl (plist-get meta :pl)))
    (->> (org-element-map pl 'item #'identity)
         (--map (substring-no-properties
                 (org-element-interpret-data
                  (org-element-contents
                   (org-element-property :tag it))))))))

(defsubst manifolding-atlas-buffer-meta-get (prop type &optional bound)
  "Get all values of metadata PROP of TYPE from buffer.
BOUND controls the scope - see `manifolding-atlas-buffer-meta' for details."
  (manifolding-atlas-buffer-meta-get! (manifolding-atlas-buffer-meta bound) prop type))

(defun manifolding-atlas-buffer-meta--get (meta prop)
  "Get all values of PROP from META.

Return plist (:file :buffer :pl :items)"
  (let* ((pl (plist-get meta :pl))
         (items-all (org-element-map pl 'item #'identity))
         (items
          (seq-filter
           (lambda (item)
             (string-equal
              prop
              (substring-no-properties
               (org-element-interpret-data
                (org-element-contents
                 (org-element-property :tag item))))))
           items-all)))
    (plist-put meta :items items)))

(defsubst manifolding-atlas-buffer-meta-get-list (prop &optional type bound)
  "Get all values of metadata PROP of TYPE as a list from buffer.
BOUND controls the scope - see `manifolding-atlas-buffer-meta' for details."
  (manifolding-atlas-buffer-meta-get-list! (manifolding-atlas-buffer-meta bound) prop type))

(defun manifolding-atlas-buffer-meta-get-list! (meta prop &optional type)
  "Get all values of PROP from META.

Each element value depends on TYPE:

- raw - org element object
- string (default) - an interpreted object (without trailing
  newline)
- number - an interpreted number
- link - path of the link (either ID of the linked note or raw link)
- note - linked `manifolding-atlas-note'
- symbol - an interned symbol."
  (setq type (or type 'string))
  (let* ((meta (manifolding-atlas-buffer-meta--get meta prop))
         (items (plist-get meta :items)))
    (if (eq type 'note)
        (let* ((kvps (cl-loop
                      for item in items
                      for val = (car (org-element-contents item))
                      for el = (car (org-element-contents val))
                      when (equal 'link (org-element-type el))
                      when (string-equal (org-element-property :type el) "id")
                      collect (cons (org-element-property :path el)
                                    (substring-no-properties (car (org-element-contents el))))))
               (ids (mapcar #'car kvps))
               (notes (cl-loop for note in (manifolding-atlas-db-query-by-ids ids)
                               unless (manifolding-atlas-note-primary-title note)
                               collect note)))
          (cl-loop
           for it in kvps
           collect (let* ((id (car it))
                          (desc (cdr it))
                          (note (--find (string-equal id (manifolding-atlas-note-id it)) notes)))
                     (when (and note
                                desc
                                (seq-contains-p (manifolding-atlas-note-aliases note) desc))
                       (setf (manifolding-atlas-note-primary-title note) (manifolding-atlas-note-title note))
                       (setf (manifolding-atlas-note-title note) desc))
                     note)))
      (cl-loop
       for item in items
       collect (let ((val (car (org-element-contents item))))
                 (pcase type
                   (`raw val)
                   (`symbol
                    (intern
                     (s-trim-right
                      (substring-no-properties
                       (org-element-interpret-data
                        (org-element-contents val))))))
                   (`string
                    (s-trim-right
                     (substring-no-properties
                      (org-element-interpret-data
                       (org-element-contents val)))))
                   (`number
                    (string-to-number
                     (s-trim-right
                      (substring-no-properties
                       (org-element-interpret-data
                        (org-element-contents val))))))
                   (`link
                    (let ((el (car (org-element-contents val))))
                      (when (equal 'link
                                   (org-element-type el))
                        (pcase (org-element-property :type el)
                          ("id" (org-element-property :path el))
                          (_ (org-element-property :raw-link el))))))))))))

(defun manifolding-atlas-buffer-meta-get! (meta prop &optional type)
  "Get value of PROP from META.

Result depends on TYPE:

- raw - org element object
- string (default) - an interpreted object (without trailing
  newline)
- number - an interpreted number
- link - path of the link (either ID of the linked note or raw link)
- note - linked `manifolding-atlas-note'
- symbol - an interned symbol.

If the note contains multiple values for a given PROP, the first
one is returned. In case all values are required, use
`manifolding-atlas-buffer-meta-get-list'."
  (car (manifolding-atlas-buffer-meta-get-list! meta prop type)))

(defun manifolding-atlas-buffer-meta-set (prop value &optional append bound)
  "Set VALUE of PROP in current buffer.

If the VALUE is a list, then each element is inserted
separately.

Please note that all occurrences of PROP are replaced by VALUE.

When PROP is not yet set, VALUE is inserted at the beginning of
the meta, unless the optional argument APPEND is non-nil, in
which case VALUE is added at the end of the meta.

BOUND controls the scope - see `manifolding-atlas-buffer-meta' for details.
When BOUND is \\='heading or a position, operates within that
heading's subtree."
  (let* ((notify (manifolding-atlas-buffer-meta--notify-p))
         (old (and notify (manifolding-atlas-buffer-meta-get-list prop 'string bound)))
         (manifolding-atlas-buffer-meta--inhibit-change t)
         (values (if (listp value) value (list value)))
         (meta (manifolding-atlas-buffer-meta--get (manifolding-atlas-buffer-meta bound) prop))
         (buffer (plist-get meta :buffer))
         (pl (plist-get meta :pl))
         (items (plist-get meta :items))
         (img (org-element-copy (car items))))
    (cond
     ;; descriptive plain list exists, update it
     (pl
      ;; TODO: inline
      (manifolding-atlas-buffer-meta-remove prop bound)
      (cond
       ;; property already set, remove it and set again
       (img
        (goto-char (org-element-property :begin img))
        (seq-do
         (lambda (val)
           (insert
            (org-element-interpret-data
             (org-element-set-contents
              (org-element-copy img)
              (manifolding-atlas-buffer-meta-format val)))))
         values)
        (when (and (equal (length items)
                          (length (org-element-contents pl)))
                   (> (length items) 1))
          (insert "\n")))

       ;; property is not yet set, simply set it
       (t
        (let* ((items-all (org-element-map pl 'item #'identity))
               ;; we copy any item from the list so we don't need to
               ;; deal with :bullet and other properties
               (img (org-element-copy (car items-all)))
               (point (if append
                          (- (org-element-property :end pl)
                             (org-element-property :post-blank pl))
                        (org-element-property :begin pl))))
          ;; when APPEND and body is present, insert new item on the
          ;; next line after the last item
          (goto-char point)
          (seq-do
           (lambda (val)
             (insert
              (org-element-interpret-data
               (org-element-set-contents
                (org-element-put-property
                 (org-element-copy img)
                 :tag
                 prop)
                (manifolding-atlas-buffer-meta-format val)))))
           values)))))

     ;; descriptive plain list does not exist, create one
     (t
      (let ((point (manifolding-atlas-buffer-meta--insertion-point buffer bound)))
        (goto-char point)
        (insert "\n")
        (seq-do
         (lambda (val)
           (insert "- " prop " :: "
                   (manifolding-atlas-buffer-meta-format val)
                   "\n"))
         values))))
    (when notify
      (manifolding-atlas-buffer-meta--notify
       prop old (manifolding-atlas-buffer-meta-get-list prop 'string bound)))))

(defun manifolding-atlas-buffer-meta--insertion-point (buffer bound)
  "Find the insertion point for new metadata.
BUFFER is the parsed org buffer.
BOUND controls the scope - see `manifolding-atlas-buffer-meta' for details."
  (cond
   ;; Heading scope - find insertion point within heading
   ((or (eq bound 'heading) (numberp bound))
    (save-excursion
      (when (numberp bound)
        (goto-char bound))
      (if (org-before-first-heading-p)
          ;; File level - use original logic
          (let ((element
                 (or
                  (car (last (org-element-map buffer 'keyword #'identity)))
                  (car (org-element-map buffer 'property-drawer #'identity)))))
            (if element
                (- (org-element-property :end element)
                   (org-element-property :post-blank element))
              (point-min)))
        ;; In a heading - find property drawer or end of heading line
        (org-back-to-heading-or-point-min t)
        (let* ((heading-pos (point))
               (section (manifolding-atlas-buffer-meta--heading-section buffer heading-pos))
               (prop-drawer (when section
                              (org-element-map section 'property-drawer
                                #'identity nil t))))
          (if prop-drawer
              (- (org-element-property :end prop-drawer)
                 (org-element-property :post-blank prop-drawer))
            ;; No property drawer - insert after heading line
            (end-of-line)
            (point))))))
   ;; Buffer scope - original logic
   (t
    (let ((element
           (or
            (car (last (org-element-map buffer 'keyword #'identity)))
            (car (org-element-map buffer 'property-drawer #'identity)))))
      (if element
          (- (org-element-property :end element)
             (org-element-property :post-blank element))
        (point-min))))))

(defun manifolding-atlas-buffer-meta-set-batch (props-alist &optional bound)
  "Set multiple meta properties in current buffer efficiently.

PROPS-ALIST is an alist where each element is (PROP . VALUE).
VALUE can be a single value or a list of values.

BOUND controls the scope - see `manifolding-atlas-buffer-meta' for details.

This function parses the buffer only once, making it much more
efficient than calling `manifolding-atlas-buffer-meta-set' multiple times.

Example:
  (manifolding-atlas-buffer-meta-set-batch
    \\='((\"status\" . \"active\")
      (\"priority\" . 1)
      (\"tags\" . (\"a\" \"b\" \"c\"))))"
  (when props-alist
    (let* ((notify (manifolding-atlas-buffer-meta--notify-p))
           (olds (and notify
                      (let ((m (manifolding-atlas-buffer-meta bound)))
                        (mapcar
                         (lambda (pair)
                           (cons (car pair)
                                 (manifolding-atlas-buffer-meta-get-list! m (car pair) 'string)))
                         props-alist))))
           (meta (manifolding-atlas-buffer-meta bound))
           (buffer (plist-get meta :buffer))
           (pl (plist-get meta :pl))
           (items-all (when pl (org-element-map pl 'item #'identity)))
           (template-item (org-element-copy (car items-all)))
           (props-to-set (mapcar #'car props-alist))
           ;; Collect all items that need to be deleted
           (items-to-delete
            (when items-all
              (seq-filter
               (lambda (item)
                 (member
                  (substring-no-properties
                   (org-element-interpret-data
                    (org-element-contents
                     (org-element-property :tag item))))
                  props-to-set))
               items-all)))
           ;; Check if we're removing all items (need to delete whole list)
           (removing-all (and items-to-delete
                              (= (length items-to-delete)
                                 (length items-all)))))
      (cond
       ;; Case 1: descriptive list exists
       (pl
        (let ((insert-point (org-element-property :begin pl)))
          ;; Delete items in reverse order to preserve positions
          (if removing-all
              ;; Delete whole list if removing all items
              (delete-region (org-element-property :begin pl)
                             (org-element-property :end pl))
            ;; Delete individual items
            (dolist (item (sort (copy-sequence items-to-delete)
                                (lambda (a b)
                                  (> (org-element-property :begin a)
                                     (org-element-property :begin b)))))
              (delete-region (org-element-property :begin item)
                             (org-element-property :end item))))
          ;; Insert new values
          (goto-char insert-point)
          (if removing-all
              ;; Need to create new list from scratch
              (dolist (pair props-alist)
                (let ((prop (car pair))
                      (values (if (listp (cdr pair)) (cdr pair) (list (cdr pair)))))
                  (dolist (val values)
                    (insert "- " prop " :: "
                            (manifolding-atlas-buffer-meta-format val)
                            "\n"))))
            ;; Use template item for formatting
            (dolist (pair props-alist)
              (let ((prop (car pair))
                    (values (if (listp (cdr pair)) (cdr pair) (list (cdr pair)))))
                (dolist (val values)
                  (insert
                   (org-element-interpret-data
                    (org-element-set-contents
                     (org-element-put-property
                      (org-element-copy template-item)
                      :tag
                      prop)
                     (manifolding-atlas-buffer-meta-format val))))))))))

       ;; Case 2: no descriptive list, create one
       (t
        (let ((point (manifolding-atlas-buffer-meta--insertion-point buffer bound)))
          (goto-char point)
          (insert "\n")
          (dolist (pair props-alist)
            (let ((prop (car pair))
                  (values (if (listp (cdr pair)) (cdr pair) (list (cdr pair)))))
              (dolist (val values)
                (insert "- " prop " :: "
                        (manifolding-atlas-buffer-meta-format val)
                        "\n")))))))
      (when notify
        (let ((m (manifolding-atlas-buffer-meta bound)))
          (dolist (pair props-alist)
            (manifolding-atlas-buffer-meta--notify
             (car pair)
             (cdr (assoc (car pair) olds))
             (manifolding-atlas-buffer-meta-get-list! m (car pair) 'string))))))))

(defun manifolding-atlas-buffer-meta-remove (prop &optional bound)
  "Delete values of PROP from current buffer.
BOUND controls the scope - see `manifolding-atlas-buffer-meta' for details."
  (let* ((notify (manifolding-atlas-buffer-meta--notify-p))
         (old (and notify (manifolding-atlas-buffer-meta-get-list prop 'string bound)))
         (meta (manifolding-atlas-buffer-meta--get (manifolding-atlas-buffer-meta bound) prop))
         (items (plist-get meta :items))
         (pl (plist-get meta :pl)))
    (when (car items)
      (if (equal (length items)
                 (length (org-element-contents pl)))
          (delete-region (org-element-property :begin pl)
                         (org-element-property :end pl))
        (seq-do
         (lambda (item)
           (when-let* ((begin (org-element-property :begin item))
                       (end (org-element-property :end item)))
             (delete-region begin end)))
         (seq-reverse items))))
    (when notify
      (manifolding-atlas-buffer-meta--notify prop old nil))))

(defun manifolding-atlas-buffer-meta-clean (&optional bound)
  "Delete all meta from current buffer.
BOUND controls the scope - see `manifolding-atlas-buffer-meta' for details."
  (let* ((notify (manifolding-atlas-buffer-meta--notify-p))
         (snapshot
          (and notify
               (let ((meta (manifolding-atlas-buffer-meta bound)))
                 (mapcar (lambda (p)
                           (cons p (manifolding-atlas-buffer-meta-get-list! meta p 'string)))
                         (manifolding-atlas-buffer-meta-props meta))))))
    (when-let* ((meta (manifolding-atlas-buffer-meta bound))
                (pl (plist-get meta :pl)))
      (delete-region
       (org-element-property :begin pl)
       (org-element-property :end pl)))
    (when notify
      (dolist (it snapshot)
        (manifolding-atlas-buffer-meta--notify (car it) (cdr it) nil)))))

(defun manifolding-atlas-buffer-meta-format (value)
  "Format a VALUE depending on it's type."
  (cond
   ((manifolding-atlas-note-p value)
    (manifolding-atlas-utils-link-make-string value))
   ((and (stringp value)
         (string-match-p (concat "^" manifolding-atlas-utils--uuid-regexp "$") value))
    (if-let* ((note (manifolding-atlas-db-get-by-id value)))
        (manifolding-atlas-utils-link-make-string note)
      (user-error "Note with id \"%s\" does not exist" value)))
   ((stringp value)
    (let ((domain (ignore-errors
                    (url-domain (url-generic-parse-url value)))))
      (if domain
          (org-link-make-string value domain)
        value)))
   ((numberp value)
    (number-to-string value))
   ((symbolp value)
    (symbol-name value))
   (t (user-error "Unsupported type of \"%s\"" value))))

(defun manifolding-atlas-buffer-meta-sort (props)
  "Sort meta in current buffer using list of PROPS.

Whatever is not part of PROPS is left in the same order but appended to
the end after PROPS."
  (let* ((manifolding-atlas-buffer-meta--inhibit-change t)
         (meta (manifolding-atlas-buffer-meta))
         (props-all (->> (org-element-map (plist-get meta :pl) 'item #'identity)
                         (--map (substring-no-properties
                                 (org-element-interpret-data
                                  (org-element-contents
                                   (org-element-property :tag it)))))))
         (props-extra (-difference props-all props)))
    (manifolding-atlas-buffer-meta-clean)
    (--each props
      (manifolding-atlas-buffer-meta-set it (manifolding-atlas-buffer-meta-get-list! meta it) 'append))
    (--each props-extra
      (manifolding-atlas-buffer-meta-set it (manifolding-atlas-buffer-meta-get-list! meta it) 'append))))



(provide 'manifolding-atlas-buffer)
