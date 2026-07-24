(require 'tab-line)
(require 'nano-theme)


;; Face for inactive tabs and  when window not selected
;; (set-face-attribute 'mode-line nil
;;                     :foreground (face-foreground 'default)
;;                     :overline (face-foreground 'default)
;;                     :height (face-attribute 'default :height)
;;                     :box nil)
;; (set-face-attribute 'mode-line-inactive nil
;;                     :overline (face-foreground 'nano-faded)
;;                     :height (face-attribute 'default :height)
;;                     :box nil)
;; (set-face-attribute 'tab-line nil
;;                     :height (face-attribute 'default :height)
;;                     :box nil)
(set-face-attribute 'tab-line-tab nil
                    :foreground (face-foreground 'nano-faded)
                    :background (face-background 'default)
                    :underline (face-foreground 'nano-faded)
                    :overline (face-background 'default)
                    :height (face-attribute 'default :height)
                    :box nil)
(set-face-attribute 'tab-line-tab-current nil
                    :foreground (face-foreground 'default)
                    :background (face-background 'default)
                    :overline (face-background 'default)
                    :underline (face-foreground 'default)
                    :weight 'regular
                    :box nil)
(set-face-attribute 'tab-line-tab-inactive nil
                    :foreground (face-foreground 'nano-faded)
                    :background (face-background 'default)
                    :underline (face-foreground 'nano-faded)
                    :overline (face-foreground 'default)
                    :box nil)
(set-face-attribute 'tab-line-highlight nil
                    :foreground (face-foreground 'default)
                    :background 'unspecified
                    :box nil)


(setq tab-line-tab-map (define-keymap
                         "<mode-line> <down-mouse-1>" #'tab-line-select-tab
                         "<mode-line> <mouse-2>"      #'tab-line-close-tab
                         "<mode-line> <down-mouse-3>" #'tab-line-tab-context-menu
                         "RET" #'tab-line-select-tab)
      tab-line-tab-close-map (define-keymap
                               "<mode-line> <mouse-1>" #'tab-line-close-tab
                               "<mode-line> <mouse-2>" #'tab-line-close-tab)
      tab-line-close-button  (propertize "   "
                                         'keymap tab-line-tab-close-map
                                         'mouse-face 'tab-line-close-highlight
                                         'help-echo "Click to close tab")
      tab-line-left-map (define-keymap
                          "<mode-line> <down-mouse-1>" #'tab-line-hscroll-left
                          "<mode-line> <down-mouse-2>" #'tab-line-hscroll-left)
      tab-line-right-map (define-keymap
                           "<mode-line> <down-mouse-1>" #'tab-line-hscroll-right
                           "<mode-line> <down-mouse-2>" #'tab-line-hscroll-right)      
      tab-line-left-button  (propertize "􁉄" 
                                        'face '(:inherit nano-faded
                                                :height 140)
                                        'keymap tab-line-left-map
                                        'mouse-face 'nano-default
                                        'help-echo "Click to scroll left")
      tab-line-right-button (propertize "􁉂"
                                        'face '(:inherit nano-faded
                                                :height 140)         
                                        'keymap tab-line-right-map
                                        'mouse-face 'nano-default
                                        'help-echo "Click to scroll left")
      tab-line-separator (propertize " " 'face '(:height 140))
      tab-line-tab-name-ellipsis "…"
      tab-line-new-button-show nil
      tab-line-auto-hscroll t
      tab-line-tab-name-truncated-max 16
      tab-line-tab-name-function #'tab-line-tab-name-truncated-buffer
      use-system-tooltips t)

(define-minor-mode tab-line-mode
  "Toggle display of tab line in the windows displaying the current buffer."
  :lighter nil
  (let ((default-value '(:eval (tab-line-format))))
    (if tab-line-mode
        (setq mode-line-format default-value)
      (setq mode-line-format ""))))

(defun tab-line-tab-name-format-default (tab tabs)
  "Default function to use as `tab-line-tab-name-format-function', which see."
  (let* ((buffer-p (bufferp tab))
         (selected-p (if buffer-p
                         (eq tab (window-buffer))
                       (cdr (assq 'selected tab))))
         (name (if buffer-p
                   (funcall tab-line-tab-name-function tab tabs)
                 (cdr (assq 'name tab))))
         (name (concat " " name))
         (face (if selected-p
                   (if (mode-line-window-selected-p)
                       'tab-line-tab-current
                     'tab-line-tab)
                 'tab-line-tab-inactive)))
    (concat (propertize " " 'face `(:background ,(face-foreground face nil t))
                            'display '(space :width (1)))
            (apply 'propertize
                   (concat 
                    (propertize (string-replace "%" "%%" name) ;; (bug#57848)
                               'keymap tab-line-tab-map
                               'help-echo (if selected-p "Current tab"
                                           "Click to select tab")
                               ;; Don't turn mouse-1 into mouse-2 (bug#49247)
                               'follow-link 'ignore
                               'mouse-face 'tab-line-highlight
                               )
                   (or (and (or buffer-p (assq 'buffer tab) (assq 'close tab))
                            tab-line-close-button-show
                            (not (eq tab-line-close-button-show
                                     (if selected-p 'non-selected 'selected)))
                            tab-line-close-button)
                       ""))
           `(tab ,tab
             ,@(if selected-p '(selected t))
             face ,face
             display (raise .2)))
            (propertize " " 'face `(:background ,(face-foreground face nil t))
                            'display '(space :width (1))))))


(provide 'init-tab-line)
