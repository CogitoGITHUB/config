;;; manifolding-emacs-splash.el --- Boot splash + dashboard -*- lexical-binding: t; -*-

;; Pure renderer: reads `manifolding-emacs-errors-list' and
;; `manifolding-emacs-warnings-list', never mutates them.  All
;; state-changing work (recording, filing to TODO, clearing) lives in
;; manifolding-emacs-errors.el.

;;; Code:

(require 'manifolding-emacs-vars)
(require 'manifolding-emacs-errors)

(defconst manifolding-emacs-splash--bar-width 54)
(defconst manifolding-emacs-splash--redraw-interval 0.1
  "Seconds between live splash redraws (throttle).")
(defconst manifolding-emacs-splash--history-length 24
  "How many past boot durations the sparkline remembers.")

(defvar manifolding-emacs-splash--state nil
  "Live render state: (:t0 :count :last-render :elapsed-final).")

(defvar manifolding-emacs-splash--history-file
  (expand-file-name ".local/cache/manifolding-boot-times"
                    user-emacs-directory))

(defun manifolding-emacs-show-splash ()
  (let ((buf (get-buffer-create "*Manifolding-Emacs*")))
    (with-current-buffer buf
      (erase-buffer)
      (let ((org-mode-hook nil)) (org-mode)))
    (condition-case nil
        (switch-to-buffer buf)
      (error nil))
    buf))

(defun manifolding-emacs-splash--record-duration (seconds)
  (make-directory (file-name-directory manifolding-emacs-splash--history-file) t)
  (let ((times (append (manifolding-emacs-splash--read-history)
                       (list seconds))))
    (when (> (length times) manifolding-emacs-splash--history-length)
      (setq times (nthcdr (- (length times)
                             manifolding-emacs-splash--history-length)
                          times)))
    (with-temp-file manifolding-emacs-splash--history-file
      (insert (prin1-to-string times)))))

(defun manifolding-emacs-splash--read-history ()
  (condition-case nil
      (let ((raw (when (file-exists-p manifolding-emacs-splash--history-file)
                   (car (read-from-string
                         (with-temp-buffer
                           (insert-file-contents
                            manifolding-emacs-splash--history-file)
                           (buffer-string)))))))
        (if (listp raw) raw nil))
    (error nil)))

(defun manifolding-emacs-splash--sparkline ()
  "Render recent boot durations as a one-line block sparkline."
  (let* ((times (manifolding-emacs-splash--read-history))
         (chars ["▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"]))
    (if (< (length times) 2)
        ""
      (let* ((mn (apply #'min times))
             (mx (apply #'max times))
             (span (max (- mx mn) 0.001)))
        (concat "  "
                (mapconcat
                 (lambda (s)
                   (let ((idx (floor (* (- (length chars) 1)
                                        (/ (- s mn) span)))))
                     (aref chars (min (1- (length chars)) (max 0 idx)))))
                 times ""))))))

(defun manifolding-emacs-splash--center (text)
  "Center each line of TEXT within the live window width."
  (let* ((win (get-buffer-window "*Manifolding-Emacs*" t))
         (w (if win (window-body-width win) 80))
         (lines (split-string text "\n")))
    (mapconcat
     (lambda (line)
       (let* ((len (length line))
              (pad (if (< len w) (make-string (/ (- w len) 2) ?\s) "")))
         (concat pad line)))
     lines "\n")))

(defun manifolding-emacs-splash--bar (current total)
  (let* ((ratio (if (zerop total) 1.0 (/ (float current) total)))
         (done (floor (* ratio manifolding-emacs-splash--bar-width)))
         (todo (- manifolding-emacs-splash--bar-width done)))
    (concat "["
            (propertize (make-string done ?█) 'face 'bold)
            (make-string todo ?·)
            "]")))

(defun manifolding-emacs-splash--group-by-file (entries)
  "Group error/warning ENTRIES by file."
  (let ((groups (make-hash-table :test #'equal))
        order)
    (dolist (e entries)
      (let* ((f (or (manifolding-emacs-error-entry-file e) "unknown"))
             (base (file-name-nondirectory f)))
        (unless (gethash base groups)
          (push base order))
        (push e (gethash base groups))))
    (mapcar (lambda (base)
              (cons base (nreverse (gethash base groups))))
            (nreverse order))))

(defun manifolding-emacs-splash--problems-section (label entries)
  "Render LABEL section for grouped ENTRIES, or empty string."
  (if (null entries)
      ""
    (let ((out (list (format "\n%s — %d\n" label (length entries)))))
      (pcase-dolist (`(,base . ,items) (manifolding-emacs-splash--group-by-file entries))
        (push (format "%s\n"
                      (propertize (format "%s (%d)" base (length items))
                                  'face 'bold))
              out)
        (dolist (e items)
          (push (format "  %s\n"
                        (manifolding-emacs-error-entry-message e))
                out)))
      (apply #'concat (nreverse out)))))

(defun manifolding-emacs-splash--eta-line (current total)
  (format "%d/%d · %d%%" current total
          (if (zerop total) 100
            (floor (* 100 (/ (float current) total))))))

(defun manifolding-emacs-splash--render-progress (buf current total file)
  (let* ((errors (manifolding-emacs-errors-list))
         (warnings (manifolding-emacs-warnings-list))
         (label (pcase manifolding-emacs--boot-phase
                  (:compiling "Compiling") (:loading "Loading") (_ "Processing")))
         (bar (manifolding-emacs-splash--bar current total))
         (eta (manifolding-emacs-splash--eta-line current total))
         (head (concat "MANIFOLDING-EMACS\n\n"
                       (propertize eta 'face 'bold) "\n\n"
                       bar "\n\n"
                       (if file
                           (concat
                            (format "%s: " label)
                            (propertize (file-name-nondirectory file)
                                        'face 'bold))
                         "")
                       "\n"
                       (format "%s%d errors · %d warnings\n"
                               (if (alist-get :fatal manifolding-emacs-splash--state)
                                   "BOOT THREW — " "")
                               (length errors) (length warnings))))
         (body (concat head
                       (manifolding-emacs-splash--problems-section
                        "ERRORS" errors)
                       (manifolding-emacs-splash--problems-section
                        "WARNINGS" warnings))))
    (with-current-buffer buf
      (let ((inhibit-read-only t)
            (org-mode-hook nil))
        (erase-buffer)
        (insert (manifolding-emacs-splash--center body))
        (goto-char (point-min))))))

(defun manifolding-emacs-splash-update-progress (buf current total file)
  (when (buffer-live-p buf)
    (let* ((now (float-time))
           (st manifolding-emacs-splash--state)
           (first-call (zerop (or (plist-get st :count) 0)))
           (changed (or (/= current (or (plist-get st :last-count) -1))
                        (/= (length (manifolding-emacs-errors-list))
                            (or (plist-get st :last-e) -1))
                        (/= (length (manifolding-emacs-warnings-list))
                            (or (plist-get st :last-w) -1)))))
      (when first-call
        (setq manifolding-emacs-splash--state
              (list :t0 now :count 0 :last-render 0
                    :last-count -1 :last-e -1 :last-w -1))
        (setq st manifolding-emacs-splash--state))
      (plist-put manifolding-emacs-splash--state :count current)
      (let* ((since (and (not first-call)
                         (- now (or (plist-get
                                     manifolding-emacs-splash--state
                                     :last-render)
                                    0))))
             (finished (>= current total)))
        (when (or first-call finished changed
                  (null since)
                  (>= since manifolding-emacs-splash--redraw-interval))
          (plist-put manifolding-emacs-splash--state :last-render now)
          (plist-put manifolding-emacs-splash--state :last-count current)
          (plist-put manifolding-emacs-splash--state :last-e
                     (length (manifolding-emacs-errors-list)))
          (plist-put manifolding-emacs-splash--state :last-w
                     (length (manifolding-emacs-warnings-list)))
          (manifolding-emacs-splash--render-progress buf current total file)
          (with-current-buffer buf
            (redisplay)))))))

(defun manifolding-emacs-splash--missing-prompts-count ()
  (condition-case nil
      (let ((path (expand-file-name
                   "admin/MISSING PROMPTS"
                   (if (fboundp 'my/manifolding-atlas-root-dir)
                       (my/manifolding-atlas-root-dir)
                     "~/test/"))))
        (if (not (file-exists-p path))
            0
          (with-temp-buffer
            (insert-file-contents path)
            (count-matches "^\\* TODO"))))
    (error 0)))

(defun manifolding-emacs-splash--notes-count ()
  (condition-case nil
      (if (fboundp 'manifolding-atlas-db-query)
          (length (manifolding-atlas-db-query))
        0)
    (error 0)))

(defun manifolding-emacs-splash-clean-finish (buf boot-seconds)
  "Show a brief CLEAN BOOT flash, then morph into the dashboard."
  (manifolding-emacs-splash--record-duration boot-seconds)
  (manifolding-emacs-splash-update-dashboard
   buf boot-seconds "CLEAN BOOT")
  (run-with-idle-timer
   1.2 nil
   (lambda () (manifolding-emacs-splash-update-dashboard
               buf boot-seconds nil))))

(defvar manifolding-emacs-splash--todos-expanded nil
  "When non-nil, the dashboard lists every module TODO instead of a few.")

(defconst manifolding-emacs-splash--modules-dir
  (expand-file-name "modules" user-emacs-directory))

(defun manifolding-emacs-splash--module-todos ()
  "Return list of (FILE-BASE . TITLE) TODO headings from modules/*.org."
  (condition-case nil
      (let ((results nil)
            (files (directory-files
                    manifolding-emacs-splash--modules-dir
                    t "\\.org\\'")))
        (dolist (f files)
          (let ((base (file-name-nondirectory f)))
            (with-temp-buffer
              (insert-file-contents f)
              (goto-char (point-min))
              (while (re-search-forward
                      "^\\*+[ \t]+TODO[ \t]+\\(.*?\\)[ \t]*$" nil t)
                (push (cons base (match-string 1)) results)))))
        (nreverse results))
    (error nil)))

(defun manifolding-emacs-splash--vault-git-info ()
  "One-line git summary of the vault, or nil when unavailable."
  (condition-case nil
      (when (fboundp 'magit-git-lines)
        (let ((root (if (fboundp 'my/manifolding-atlas-root-dir)
                        (my/manifolding-atlas-root-dir)
                      "~/test/")))
          (let* ((branch (car (magit-git-lines "-C" root
                                               "rev-parse" "--abbrev-ref" "HEAD")))
                 (last (car (magit-git-lines "-C" root
                                             "log" "-1" "--format=%cr")))
                 (ahead (car (magit-git-lines "-C" root
                                              "rev-list" "--count"
                                              "@{upstream}..HEAD"))))
            (concat (or branch "?")
                    (if last (format " · %s" last) " · no commits")
                    (when (and ahead (not (string= ahead "0")))
                      (format " · ↑%s" ahead))))))
    (error nil)))

(defun manifolding-emacs-splash-update-dashboard (buf boot-seconds banner)
  (when (buffer-live-p buf)
    (let* ((errors (length (manifolding-emacs-errors-list)))
           (warnings (length (manifolding-emacs-warnings-list)))
           (notes (manifolding-emacs-splash--notes-count))
           (missing (manifolding-emacs-splash--missing-prompts-count))
           (missing-path (expand-file-name
                          "admin/MISSING PROMPTS"
                          (if (fboundp 'my/manifolding-atlas-root-dir)
                              (my/manifolding-atlas-root-dir)
                            "~/test/")))
           (git-line (manifolding-emacs-splash--vault-git-info))
           (todos (manifolding-emacs-splash--module-todos))
            (todo-lines
             (when todos
               (let* ((shown (if manifolding-emacs-splash--todos-expanded
                                 todos
                               (let ((n 0) acc)
                                 (dolist (td todos)
                                   (when (< n 3)
                                     (push td acc)
                                     (setq n (1+ n))))
                                 (nreverse acc))))
                     (out (list (format "module TODOs: %d%s\n"
                                        (length todos)
                                        (if (> (length todos) 3)
                                            (concat "  [t] "
                                                    (if manifolding-emacs-splash--todos-expanded
                                                        "collapse"
                                                      "show all"))
                                          "")))))
                (dolist (td shown)
                  (push (format "  %s: %s\n"
                                (propertize (car td) 'face 'bold)
                                (cdr td))
                        out))
                (apply #'concat (nreverse out)))))
           (body (concat
                  "MANIFOLDING ATLAS — "
                  (propertize (or banner "READY") 'face 'bold)
                  "\n\n"
                  (propertize
                   (format "boot %.1fs" boot-seconds) 'face 'bold)
                  (manifolding-emacs-splash--sparkline)
                  "\n\n"
                  (format "modules compiled · errors %d · warnings %d\n"
                          errors warnings)
                  (format "vault notes: %d · missing prompts: %d\n"
                          notes missing)
                  (when git-line (format "git: %s\n" git-line))
                  (or todo-lines "")
                  "\n[g] reload    [m] missing prompts    [q] dismiss\n"
                  (when (fboundp 'magit-status)
                    "[p] push    [G] magit\n")))
           (inhibit-read-only t))
      (with-current-buffer buf
        (erase-buffer)
        (insert (manifolding-emacs-splash--center body))
        (goto-char (point-min))
        (use-local-map
         (let ((map (make-sparse-keymap)))
           (define-key map "g"
                       (lambda () (interactive) (manifolding-emacs-reload)))
           (define-key map "m"
                       (lambda () (interactive)
                         (find-file missing-path)))
           (define-key map "q" #'quit-window)
           (define-key map "t"
                       (lambda () (interactive)
                         (setq manifolding-emacs-splash--todos-expanded
                               (not manifolding-emacs-splash--todos-expanded))
                         (manifolding-emacs-splash-update-dashboard
                          buf boot-seconds banner)))
           (when (and (fboundp 'my/manifolding-atlas-root-dir)
                      (fboundp 'my/manifolding-atlas-git--push))
             (define-key map "p"
                         (lambda () (interactive)
                           (message "Manifolding Atlas: pushing notes...")
                           (my/manifolding-atlas-git--push
                            (expand-file-name
                             "admin/MISSING PROMPTS"
                             (my/manifolding-atlas-root-dir))))))
           (when (fboundp 'magit-status)
             (define-key map "G"
                         (lambda () (interactive)
                           (magit-status
                            (if (fboundp 'my/manifolding-atlas-root-dir)
                                (my/manifolding-atlas-root-dir)
                              default-directory)))))
           map))
        (redisplay)))))

(provide 'manifolding-emacs-splash)
;;; manifolding-emacs-splash.el ends here
