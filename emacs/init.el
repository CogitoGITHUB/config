;; Set C-x C-b to open ibuffer instead of default list-buffers
(global-set-key (kbd "C-x C-b") 'ibuffer)





(use-package modus-themes
;;  :straight t
  :init
  ;; Light theme: clean paper
  (defvar shapeshifter/modus-operandi-monochrome
    '((bg-main           "#ffffff")
      (fg-main           "#000000")
      (bg-alt            "#e5e5e5")
      (fg-alt            "#1a1a1a")
      (bg-region         "#cccccc")
      (fg-region         "#000000")
      (comment           "#888888")
      (string            "#333333")
      (keyword           "#111111")
      (builtin           "#111111")
      (constant          "#222222")
      (function          "#111111")
      (variable          "#111111")
      ;; Unified org heads (light)
      (fg-heading-1      "#000000")
      (fg-heading-2      "#000000")
      (fg-heading-3      "#000000")
      (fg-heading-4      "#000000")
      (fg-heading-5      "#000000")
      (fg-heading-6      "#000000")))

  ;; Dark theme: grayscale + red comments
  (defvar shapeshifter/modus-vivendi-greyscale-red-comments
    '((bg-main           "#000000")
      (fg-main           "#dddddd")
      (bg-alt            "#111111")
      (fg-alt            "#aaaaaa")
      (bg-region         "#222222")
      (fg-region         "#ffffff")
      (comment           "#ff4444")
      (string            "#bbbbbb")
      (keyword           "#cccccc")
      (builtin           "#cccccc")
      (constant          "#999999")
      (function          "#dddddd")
      (variable          "#bbbbbb")
      (type              "#dddddd")
      ;; Org headings
      (fg-heading-1      "#dddddd")
      (fg-heading-2      "#dddddd")
      (fg-heading-3      "#dddddd")
      (fg-heading-4      "#dddddd")
      (fg-heading-5      "#dddddd")
      (fg-heading-6      "#dddddd")
      ;; UI
      (border            "#222222")
      (fg-line-number    "#555555")
      (bg-line-number    "#111111")
      (cursor            "#ffffff")))

  ;; Tab-bar color mapping per theme
  (defvar shapeshifter/tab-bar-theme-colors
    '((modus-operandi
       :bar-bg "#ffffff" :bar-fg "#000000"
       :tab-bg "#eeeeee" :tab-fg "#000000"
       :inactive-bg "#dddddd" :inactive-fg "#555555")
      (modus-vivendi
       :bar-bg "#000000" :bar-fg "#ffffff"
       :tab-bg "#000000" :tab-fg "#ffffff"
       :inactive-bg "#000000" :inactive-fg "#777777")))

  (defun shapeshifter/apply-tab-bar-theme (theme)
    "Set tab-bar faces based on THEME mapping."
    (let* ((props (alist-get theme shapeshifter/tab-bar-theme-colors))
           (bar-bg (plist-get props :bar-bg))
           (bar-fg (plist-get props :bar-fg))
           (tab-bg (plist-get props :tab-bg))
           (tab-fg (plist-get props :tab-fg))
           (inactive-bg (plist-get props :inactive-bg))
           (inactive-fg (plist-get props :inactive-fg)))
      (custom-set-faces
       `(tab-bar ((t (:background ,bar-bg :foreground ,bar-fg))))
       `(tab-bar-tab ((t (:background ,tab-bg :foreground ,tab-fg :weight bold))))
       `(tab-bar-tab-inactive ((t (:background ,inactive-bg :foreground ,inactive-fg)))))))

  ;; Apply theme + tab-bar style
  (defun shapeshifter/apply-modus-theme (theme)
    (interactive)
    (mapc #'disable-theme custom-enabled-themes)
    (setq modus-themes-common-palette-overrides
          (pcase theme
            ('modus-operandi shapeshifter/modus-operandi-monochrome)
            ('modus-vivendi shapeshifter/modus-vivendi-greyscale-red-comments)
            (_ nil)))
    (load-theme theme :no-confirm)
    (shapeshifter/apply-tab-bar-theme theme))

  ;; Start dark & edgy
  (defvar shapeshifter/current-theme 'modus-vivendi)
  (shapeshifter/apply-modus-theme shapeshifter/current-theme)

  ;; Toggle between themes
  (defun shapeshifter/toggle-modus-theme ()
    (interactive)
    (setq shapeshifter/current-theme
          (if (eq shapeshifter/current-theme 'modus-operandi)
              'modus-vivendi
            'modus-operandi))
    (shapeshifter/apply-modus-theme shapeshifter/current-theme))

  (global-set-key (kbd "<f5>") #'shapeshifter/toggle-modus-theme)) 












;; --- DENOTE ---
(use-package denote
  :straight (denote :type git :host github :repo "protesilaos/denote")
  :init
  (setq denote-directory "~/The grand index of T.O.E/"
        denote-file-type 'org
        denote-date-format "%Y-%m-%d"
        denote-known-keywords '("emacs" "philosophy" "ai" "cosmos" "blackhole"))

  :config
  ;; Auto-create org-id when creating a new Denote file
  (add-hook 'denote-after-new-note-hook #'org-id-get-create)

  ;; Keybindings
  (define-key global-map (kbd "C-c n n") #'denote)
  (define-key global-map (kbd "C-c n l") #'denote-link)
  (define-key global-map (kbd "C-c n b") #'denote-backlinks)
  (define-key global-map (kbd "C-c n r") #'denote-rename-file)
  (define-key global-map (kbd "C-c n s") #'my/denote-in-subdirectory)


(defun my/denote-in-subdirectory ()
  "Prompt for a subdirectory under `denote-directory`, create it if missing, and create a note there."
  (interactive)
  (let* ((root (expand-file-name denote-directory))
         (subdirs (seq-filter
                   (lambda (f)
                     (and (file-directory-p f)
                          (not (string-match-p "/\\.$\\|/\\.\\.$" f))))
                   (directory-files root t "^[^.]")))
         (choices (mapcar (lambda (f)
                            (string-remove-prefix root f))
                          subdirs))
         (chosen (completing-read
                  "Choose (or type new) subfolder (blank = root): "
                  choices nil nil))) ;; nil for require-match lets you type new
    (let ((target-dir (if (string-empty-p chosen)
                          root
                        (expand-file-name chosen root))))
      ;; Create subdirectory if it doesn’t exist
      (unless (file-directory-p target-dir)
        (make-directory target-dir t))
      ;; Temporarily bind denote-directory to target
      (let ((denote-directory target-dir))
        (call-interactively #'denote)))))

(defun my/denote-get-title (file)
  "Return the title of a Denote note FILE, or derive from filename if none."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (if (re-search-forward "^#\\+title:[ \t]*\\(.*\\)$" nil t)
        (string-trim (match-string 1))
      ;; fallback to filename base
      (file-name-base file))))

  )

;; --- ORG-ID ---
(use-package org-id
  :after org
  :config
  (setq org-id-link-to-org-use-id 'create-from-current)
  ;; ensure IDs are persistent between sessions
  (setq org-id-locations-file (expand-file-name "org-id-locations" user-emacs-directory))
  (org-id-update-id-locations))


;; --- ORG-ROAM ---
(use-package org-roam
  :straight (org-roam :type git :host github :repo "org-roam/org-roam")
  :after org
  :defer t
  :commands (org-roam-node-find org-roam-node-insert org-roam-graph)
  :init
  (setq org-roam-directory (expand-file-name "~/The grand index of T.O.E/")
        org-roam-db-location (expand-file-name "org-roam.db" user-emacs-directory)
        org-roam-file-extensions '("org"))
  :config
  (require 'org-roam-protocol)
  (org-roam-db-autosync-mode)
  ;; Sync database when new Denote notes are created
  (add-hook 'denote-after-new-note-hook #'org-roam-db-sync)
  (add-hook 'denote-rename-file-hook #'org-roam-db-sync)
  ;; Ensure all symbols are defined before native comp
  (eval-when-compile
    (declare-function org-roam-node-create "org-roam-node")
    (declare-function org-roam-node-file "org-roam-node")
    (declare-function org-roam-node-point "org-roam-node")
    (declare-function org-roam-db-node-p "org-roam-db"))
  ;; Keybindings
  (define-key global-map (kbd "C-c r f") #'org-roam-node-find)
  (define-key global-map (kbd "C-c r i") #'org-roam-node-insert)
  (define-key global-map (kbd "C-c r g") #'org-roam-graph))

;; --- ORG-ROAM-UI ---
(use-package org-roam-ui
  :straight (org-roam-ui :type git :host github :repo "org-roam/org-roam-ui")
  :after org-roam
  :defer t
  :config
  ;; Silences warnings for undefined UI functions
  (eval-when-compile
    (declare-function orui-sync-theme "org-roam-ui")
    (declare-function orui-node-local "org-roam-ui")
    (declare-function orui-node-zoom "org-roam-ui")
    (declare-function orui-open "org-roam-ui"))
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))
