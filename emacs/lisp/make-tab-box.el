;;; make-tab-box.el --- Box with tabs -*- lexical-binding: t -*-


(defun make-button (label &optional active)
  (let* ((fg (if active
                 (face-foreground 'default)
               (face-foreground 'font-lock-comment-face nil t)))
         (bg (face-background 'default))
         (ul (if active bg (face-foreground 'default)))
         (vline-face `(:background ,fg :height 10 :overline ,fg
                       :underline (:color ,(face-foreground 'default) :position t)))
         (label-face `(:foreground ,fg :background ,bg :overline ,fg
                       :underline (:color ,ul :position t)))
         (vline (propertize " " 'font-lock-face vline-face 'face vline-face)))
    (concat vline
            (propertize (concat " " label " ")
                        'font-lock-face label-face
                        'face label-face)
            vline)))

(insert (concat (make-button "TEST" t)
                "\n\n"
                (make-button "TEST")))


(defun make-tab-box (paragraphs &optional active)

  (setq left-margin-width (max 1 left-margin-width)
        right-margin-width (max 2 right-margin-width))
  (set-window-margins nil left-margin-width right-margin-width)
  (set-window-buffer nil (current-buffer))

  (let* ((active (or active 0))
         (fg (face-foreground 'default))
         (bg (face-background 'default))
         (separator (propertize " " 'face `(:underline (:color ,(face-foreground 'default) position t)
                                                        :height .75)
                                     'font-lock-face `(:underline (:color ,(face-foreground 'default) position t)
                                                       :height .75)))
         (margins (concat
                   (propertize " " 'display `((margin left-margin)
                                              ,(concat (propertize " " 'face `(:background ,fg :height 10))
                                                       (propertize " " 'face `(:background ,bg :height 10)))))
                   (propertize " " 'display `((margin right-margin)
                                              ,(concat (propertize " " 'face `(:background ,bg))
                                                       (propertize " " 'face `(:background ,fg :height 10))
                                                       (propertize " " 'face `(:background ,bg)))))))
         (margins-top (concat
                   (propertize " " 'display `((margin left-margin)
                                              ,(concat (propertize " " 'face `(:underline (:color ,fg :position t)
                                                                               :background ,bg
                                                                               ))
                                                       )))
                   (propertize " " 'display `((margin right-margin)
                                              ,(concat (propertize " " 'face `(:underline (:color ,fg :position t)
                                                                               :background ,bg))
                                                       (propertize " " 'face `(:underline (:color ,fg :position t)
                                                                                :height 10)))))))
         (margins-bot (concat
                       (propertize " " 'display `((margin left-margin)
                                                  ,(concat (propertize " " 'face `(:background ,fg :height 10))
                                                           (propertize " " 'face `(:underline ,fg :background ,bg)))))
                       (propertize " " 'display `((margin right-margin)
                                                  ,(concat (propertize " " 'face `(:underline ,fg :background ,bg))
                                                           (propertize " " 'face `(:underline ,fg :background ,fg :height 10))
                                                           (propertize " " 'face `(:background ,bg))))))))
    (let ((index 0))
      (dolist (paragraph paragraphs)
        (let ((header (car paragraph)))
          (insert (concat (propertize (make-button header (eq index active))
                              'wrap-prefix margins-top
                              'line-prefix margins-top)
                          separator))
          (setq index (1+ index)))))

    (insert (propertize "\n"
                        'font-lock-face '(:underline t :extend t)
                        'wrap-prefix margins 'line-prefix margins))

    (let ((index 0))
      (dolist (paragraph paragraphs)
        (let ((content (cdr paragraph)))
          (insert
           (propertize (concat "\n" content)
                       'invisible (not (eq index active))
                       'wrap-prefix margins 'line-prefix margins)))
        (setq index (1+ index))))

    (insert
     (concat
      "\n"
      (propertize "\n" 'face `(:underline 'fg :extend t)
                       'font-lock-face `(:underline ,fg :extend t)
                       'invisible nil
                       'wrap-prefix margins-bot
                       'line-prefix margins-bot)))))

(let ((paragraphs  '(("Header 1" . "Content 1")
                     ("Header 2" . "Content 2")
                     ("Header 3" . "Content 3"))))
  (make-tab-box paragraphs 0)
  (insert "\n")
  (make-tab-box paragraphs 1)
  (insert "\n")
  (make-tab-box paragraphs 2))
