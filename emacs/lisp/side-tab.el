;;; sidetabs.el --- Left side tabs -*- lexical-binding: t; -*-


(defun sidetabs--get-user-buffers ()
  "Return an alphabetically sorted list of non-special buffer names."
  (let (user-bufs)
    (dolist (buf (buffer-list))
      (let ((name (buffer-name buf)))
        (unless (or (string-prefix-p " " name)
                    (string-prefix-p "*" name))
          (push name user-bufs))))
    (sort user-bufs #'string<)))

(defun sidetabs--select-buffer (event)
  "Switch to the buffer clicked in the sidebar."
  (interactive "e")
  (let* ((pos (posn-point (event-start event)))
         (buf-name (get-text-property pos 'sidetabs-buffer)))
    (when buf-name
      (select-window (window-main-window))
      (switch-to-buffer buf-name)
      (sidetabs-update))))

(defun sidetabs--window-setup (window)
  (with-selected-window window
    (setq-local truncate-lines t)
    (setq-local mode-line-format nil)
    (setq-local header-line-format nil)
    (setq-local cursor-type nil)
    (set-window-start window (point-min))
    (set-window-parameter window 'fixed-window-start t)
    (let ((name (buffer-name (window-buffer window))))
      (set-window-parameter 
       window 'window-fixed-size 
       (cond ((member name '("*sidetabs-top*" "*sidetabs-bottom*")) 'height)
             ((member name '("*sidetabs-left*" "*sidetabs-right*")) 'width)
             (t nil))))    
    (force-mode-line-update)))

(defun sidetabs--render-top ()
  "Render top bar. Junction depends on whether the first tab is active."
  (let* ((names (sidetabs--get-user-buffers))
         (main-win (window-main-window))
         (current-buf (and main-win (buffer-name (window-buffer main-win))))
         (is-first-active (string= (car names) current-buf))
         (left-win (get-buffer-window "*sidetabs-left*"))
         (left-w (if left-win (window-width left-win) 0)))
    (with-current-buffer (get-buffer-create "*sidetabs-top*")
      (let ((inhibit-read-only t))
        (sidetabs--ensure-display-table ?┐)
        (erase-buffer)
        (if (<= left-w 1)
            (insert "┌" (make-string 1024 ?─))
          (insert "┌" (make-string (- left-w 3) ?─)
                  (if is-first-active "─" "┬")
                  (make-string 1024 ?─)))))))

(defun sidetabs--render-bottom ()
  "Render bottom bar with padding to align with the main window area."
  (let* ((left-win (get-buffer-window "*sidetabs-left*"))
         (left-w (if left-win (- (window-width left-win) 2) 0)))
    (with-current-buffer (get-buffer-create "*sidetabs-bottom*")
      (sidetabs--ensure-display-table ?┘)
      (erase-buffer)
      (insert (make-string left-w ?\s) 
              "└" 
              (make-string 1024 ?─)))))

(defun sidetabs--render-right ()
  (with-current-buffer (get-buffer-create "*sidetabs-right*")
    (let ((inhibit-read-only t))
      (sidetabs--ensure-display-table ?│)
      (erase-buffer)
      (dotimes (_ 1024) (insert "   \n")))))

(defun sidetabs--render-left ()
  "Render tabs: bold for active, shadow for inactive."
  (let* ((names (sidetabs--get-user-buffers))
         (main-win (window-main-window))
         (current-buf (and main-win (buffer-name (window-buffer main-win))))
         (active (or (seq-position names current-buf) 0))
         (win (get-buffer-window "*sidetabs-left*")))
    (when win

      ;; Resize window according to names length
      ;; (let* ((width (if names
      ;;                   (+ (seq-max (mapcar #'length names)) 5)
      ;;                 20))
      ;;        (delta (- width (window-width win))))
      ;;   (unless (zerop delta)
      ;;     (window-resize win delta t)))
      
      (with-current-buffer (get-buffer-create "*sidetabs-left*")
        (let* ((inhibit-read-only t)
               (width (- (window-width win) 5))
               (bar (make-string (+ width 2) ?─)))
          (erase-buffer)
          (dotimes (i (length names))
            (let* ((name (nth i names))
                   (is-active (= i active))
                   (is-first (= i 0))
                   (is-last (= i (+ (length names) 1)))
                   (is-prev-active (and (not is-first) (= (1- i) active)))
                   (map (make-sparse-keymap))
                   (name-face (if is-active 'bold 'shadow)))              
              (define-key map [mouse-1] #'sidetabs--select-buffer)

              (unless is-first
                (insert "├" bar (cond (is-active      "┘")
                                      (is-prev-active "┐")
                                      (t              "┤")) "\n"))
              (insert "│ " 
                      (propertize (truncate-string-to-width name width 0 ?\s)
                                  'face name-face
                                  'mouse-face 'highlight
                                  'help-echo "Click to switch"
                                  'local-map map
                                  'sidetabs-buffer name)
                      (if is-active "  " " │") 
                      "\n")))
          (let ((is-last-active (= (1- (length names)) active)))
            (insert "└" bar (if is-last-active "┐" "┤") "\n"))
          
          (dotimes (_ 1024)
            (insert (make-string (+ width 3) ?\s) "│\n")))))))

(defun sidetabs--ensure-display-table (corner-char)
  (unless buffer-display-table
    (let ((dt (make-display-table)))
      (set-display-table-slot dt 'truncation (make-glyph-code corner-char))
      (setq-local buffer-display-table dt))))

(defun sidetabs-update (&optional _args)
  "Refresh all 4 sidetabs windows."
  (interactive)
  (when (and sidetabs-mode (get-buffer-window "*sidetabs-left*"))
    ;; Render order matters
    (sidetabs--render-left)
    (sidetabs--render-top)
    (sidetabs--render-bottom)
    (sidetabs--render-right)))

(define-minor-mode sidetabs-mode
  "Global minor mode for boxed sidebars."
  :global t
  (if sidetabs-mode
      (let ((p '((no-other-window . t)
                 (no-delete-other-windows . t))))
        (setq window-min-width 2
              window-safe-min-width 2
              window-min-height 1)
        (display-buffer-in-side-window (get-buffer-create "*sidetabs-top*") 
                                       `((side . top)
                                         (window-height . 1)
                                         (window-parameters . ,p)
                                         (body-function . sidetabs--window-setup)))
        (display-buffer-in-side-window (get-buffer-create "*sidetabs-bottom*") 
                                       `((side . bottom) (window-height . 1)
                                         (window-parameters . ,p)
                                         (body-function . sidetabs--window-setup)))
        (display-buffer-in-side-window (get-buffer-create "*sidetabs-left*") 
                                       `((side . left) (window-width . 20)
                                         (window-parameters . ,p)
                                         (body-function . sidetabs--window-setup)))
        (display-buffer-in-side-window (get-buffer-create "*sidetabs-right*") 
                                       `((side . right)
                                         (window-width . 2)
                                         (window-parameters . ,p)
                                         (body-function . sidetabs--window-setup)))
        (add-hook 'window-configuration-change-hook #'sidetabs-update)
        (sidetabs-update))
    (progn    
      (remove-hook 'window-configuration-change-hook #'sidetabs-update)
      (window-toggle-side-windows))))

;; (bind-key (kbd "M-t") #'sidetabs-mode)
