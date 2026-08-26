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
Search recursively under schema/ for the file."
  (let* ((file (my/manifolding-atlas--help-file name))
          (properties-dir (expand-file-name "modules/manifolding-atlas/schema/"
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
    ;; Only real keywords feed the heading carrier — the WARNING
    ;; skip sentinel must never prefix the created heading.
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

(defun my/manifolding-atlas-collect-prompts (context &rest extra-contexts)
  "Run all registered prompts matching CONTEXT (or any of EXTRA-CONTEXTS).
When CONTEXT is a list, match prompts whose contexts overlap with it.
Single-symbol callers (like `(my/manifolding-atlas-collect-prompts 'file)`) continue working.
When `my/manifolding-atlas-collect-defer' is non-nil, declarative
buffer-UI prompts are queued on
`my/manifolding-atlas-org-prompt--deferred' and answered later by
`my/manifolding-atlas-org-prompt--session-maybe-start'."
  (let* ((contexts (if (listp context) context (cons context extra-contexts)))
         result
         deferred-list)
    (dolist (spec my/manifolding-atlas-prompt-registry)
      (when (seq-intersection contexts (plist-get spec :contexts) #'eq)
        (let* ((key (plist-get spec :key))
               (declared (and (fboundp
                               'my/manifolding-atlas-org-prompt--declarative-p)
                              (my/manifolding-atlas-org-prompt--declarative-p
                               key)))
               (dspec (my/manifolding-atlas-collect--dspec-for key))
               (quiet my/manifolding-atlas-org-prompt--defaults-only)
               ;; Silenced = fast modes (quiet) OR SELECTION mode where
               ;; the key was not picked.  Applies to declarative AND
               ;; legacy elisp prompts alike.
               (silent (and (or quiet
                                my/manifolding-atlas-org-prompt--custom-set)
                            (not (and my/manifolding-atlas-org-prompt--custom-set
                                      (member key
                                              my/manifolding-atlas-org-prompt--custom-set)))))
                (defer (and (my/manifolding-atlas-collect--defer-p dspec)
                            (or (not silent)
                                (member key
                                        my/manifolding-atlas-org-prompt--custom-set))))
                (template-skip (and dspec
                                    (not quiet)
                                    (eq (plist-get dspec :kind) 'template)))
                (frag (cond
                       ;; Interactive-only kinds (TEMPLATE) stand down in capture flows.
                       ((or template-skip defer)
                        (when defer
                          (setq deferred-list
                                (my/manifolding-atlas-collect--queue-deferred
                                 key dspec deferred-list)))
                        nil)
                       ;; Non-declarative silenced prompts just skip —
                       ;; they have no fragment machinery of their own.
                       ((and silent (not dspec))
                        nil)
                       (silent
                        (my/manifolding-atlas-collect--silent-fragment dspec))
                       (t
                        (my/manifolding-atlas-collect--run-interactive
                         spec context declared)))))
          (when frag
            (setq result (my/manifolding-atlas-collect--merge-fragment
                          result frag))))))
    (when deferred-list
      ;; Both sweeps can queue the same key (file captures pass the
      ;; same contexts as specialized AND general) — ask each only once.
      (let (seen unique)
        (dolist (req (nreverse deferred-list))
          (let ((k (plist-get (plist-get req :spec) :key)))
            (unless (member k seen)
              (push k seen)
              (push req unique))))
        (setq my/manifolding-atlas-org-prompt--deferred
              (append my/manifolding-atlas-org-prompt--deferred
                      (nreverse unique)
                      nil))))
    result))

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

(defun my/manifolding-atlas-collect--custom-candidates (contexts)
  "Return (LABEL . KEY) candidates for CONTEXTS."
  (let ((cands nil))
    (dolist (spec my/manifolding-atlas-prompt-registry)
      (when (seq-intersection contexts (plist-get spec :contexts) #'eq)
        (let ((key (plist-get spec :key)))
          (unless (equal key "TEMPLATE")
            (push (cons (format "%s · %s"
                                (or (plist-get spec :label) key) key)
                        key)
                  cands)))))
    (push (cons "Body Template · choose the body template now"
                'body-template)
          cands)))

(defun my/manifolding-atlas-collect--fallback-choose (contexts)
  "Bulletproof SELECTION picker: completing-read-multiple over candidates."
  (let* ((cands (my/manifolding-atlas-collect--custom-candidates contexts))
         (picked (completing-read-multiple
                  "Customize which properties (comma between picks): "
                  (mapcar #'car cands)))
         (ids (delq nil
                    (mapcar (lambda (p) (cdr (assoc p cands))) picked))))
    (when (memq 'body-template ids)
      ;; Pre-answer the end-of-flow template chooser.
      (setq my/manifolding-atlas--chosen-capture
            (my/manifolding-atlas--choose-capture))
      (message "Body template locked: %s"
               my/manifolding-atlas--chosen-capture))
    (remq 'body-template ids)))

(defun my/manifolding-atlas-collect--choose-custom (contexts)
  "Ask which properties to customize for this capture.
Opens the toggle grid as SPC P does. On failure, falls back to
completing-read-multiple and surfaces the error in *Warnings*."
  (if (fboundp 'my/manifolding-atlas-select-properties-menu)
      (condition-case err
          (my/manifolding-atlas-select-properties-menu contexts)
        (error
         (warn "Manifolding Atlas: toggle grid failed: %s\nFalling back to completing-read."
               (error-message-string err))
         (my/manifolding-atlas-collect--fallback-choose contexts)))
    (warn "Manifolding Atlas: select-properties-menu not loaded — using completing-read fallback.")
    (my/manifolding-atlas-collect--fallback-choose contexts)))

(defun my/manifolding-atlas-collect--selection-fast-level (specialized-contexts general-contexts)
  "Ask which keys fire; store them and return effective level.
An empty pick list means nothing gets asked: effective level 2."
  (setq my/manifolding-atlas-org-prompt--custom-set
        (my/manifolding-atlas-collect--choose-custom
         (append (if (listp specialized-contexts)
                     specialized-contexts
                   (list specialized-contexts))
                 (if (listp general-contexts)
                     general-contexts
                   (list general-contexts)))))
  (if my/manifolding-atlas-org-prompt--custom-set 1 2))

(defun my/manifolding-atlas--dedupe-properties (props)
  "Drop later PROPS pairs whose KEY already appeared."
  (let (seen out)
    (dolist (pair props (nreverse out))
      (let ((key (car pair)))
        (unless (member key seen)
          (push key seen)
          (push pair out))))))

(defun my/manifolding-atlas-collect-prompts-with-fast (specialized-contexts general-contexts &optional fast-level)
  "Collect prompts using fast mode levels.
SPECIALIZED-CONTEXTS fire at level 0 and 1, skip at level >= 2.
GENERAL-CONTEXTS fire only at level 0, skip at level >= 1.
Level 4 (SELECTION) asks which properties to customize: those fire,
everything else defaults.  Returns merged plist with :tags,
:properties, :body, :post-apply.
When FAST-LEVEL is nil, prompts the user via `my/manifolding-atlas--fast-level'."
  (setq my/manifolding-atlas-org-prompt--deferred nil)
  (let* ((fast0 (or fast-level (my/manifolding-atlas--fast-level)))
         (fast (if (= fast0 4)
                   (my/manifolding-atlas-collect--selection-fast-level
                    specialized-contexts general-contexts)
                 fast0))
         (my/manifolding-atlas-collect-defer t)
         (spec (cond
                ;; SELECTION: picked keys must actually run, so never
                ;; stifle the specialized side when a pick list exists.
                ((and (= fast 1) my/manifolding-atlas-org-prompt--custom-set)
                 (my/manifolding-atlas-collect-prompts specialized-contexts))
                ((>= fast 2)
                 (my/manifolding-atlas--collect-default-prompts specialized-contexts))
                (t
                 (my/manifolding-atlas-collect-prompts specialized-contexts))))
         (gen  (cond
                ((= fast 0)
                 (my/manifolding-atlas-collect-prompts general-contexts))
                ;; SELECTION: picked general-context keys fire too.
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
    (dolist (health (manifolding-atlas-schema-collection-health))
      (let ((schema-name (manifolding-atlas-schema-health-schema health)))
        (dolist (pair (manifolding-atlas-schema-health-invalid-notes health))
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
  "Rebuild MISSING PROMPTS from schema health data.
Lists all notes with schema violations, grouped by schema.
Each entry includes violation details in the property drawer."
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

(defun my/manifolding-atlas--heading-schedule-apply (val note)
  "Post-apply: set SCHEDULED to VAL on NOTE.
Argument order is (val note) for use with apply-partially."
  (manifolding-atlas-visit note)
  (org-schedule nil val)
  (save-buffer)
  (kill-buffer))

(defun my/manifolding-atlas--heading-deadline-apply (val note)
  "Post-apply: set DEADLINE to VAL on NOTE.
Argument order is (val note) for use with apply-partially."
  (manifolding-atlas-visit note)
  (org-deadline nil val)
  (save-buffer)
  (kill-buffer))

(defvar my/manifolding-atlas--pending-post-apply nil
  "Post-apply functions for current note creation.
Set by `my/manifolding-atlas--default-create-fn', consumed by the capture functions.")
