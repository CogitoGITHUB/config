;;; capture.el --- Key-selection region & heading capture for manifolding-atlas v2 -*- lexical-binding: t; -*-

(require 'manifolding-atlas)
(require 'manifolding-atlas-db)
(require 'org)

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
    (manifolding-atlas-visit note)
    (goto-char (point-min))
    (when (looking-at ":PROPERTIES:")
      (re-search-forward "^:END:" nil t)
      (forward-line 1))
    (end-of-line)
    (forward-line 1)
    (delete-region (point) (point-max))
    (insert body)
    (save-buffer)
    ;; Backlink or delete — work in the original buffer
    (with-current-buffer original-buffer
      (save-excursion
        (org-back-to-heading t)
        (if (string= (read-answer "Insert backlink? "
                        '(("yes" ?y "insert backlink")
                          ("no"  ?n "delete heading without link")))
                     "yes")
            (let* ((desc (read-string "Description (blank = title): "))
                   (link-desc (unless (string-empty-p desc) desc)))
              (my/manifolding-atlas--replace-heading-with-link
               (manifolding-atlas-note-id note) (or link-desc title)))
          (my/manifolding-atlas--delete-heading))))
    (message "Extracted → %s" (manifolding-atlas-note-title note))))
