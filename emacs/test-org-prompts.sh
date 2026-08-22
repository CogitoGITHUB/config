#!/bin/sh
# Test each src block of org-prompts.org individually
EMACS=emacs
FILE="$HOME/.config/emacs/modules/manifolding-atlas/infra/capture/org-prompts.org"

$EMACS --batch --eval "
(require 'org)
(require 'cl-lib)
(with-temp-buffer
  (insert-file-contents \"$FILE\")
  (let ((org-mode-hook nil)) (org-mode))
  (goto-char (point-min))
  (let ((block-num 0) (failures 0))
    (org-babel-map-src-blocks nil
      (setq block-num (1+ block-num))
      (let* ((element (org-element-context))
             (body (org-element-property :value element))
             (lang (org-element-property :language element))
             (beg (org-element-property :begin element))
             (line (line-number-at-pos beg)))
        (when (and body (string= lang \"emacs-lisp\"))
          (condition-case err
              (progn
                (eval (read (format \"(progn\n%s\n)\" body)) t)
                (message \"Block %d (line %d): OK\" block-num line))
            (error
             (setq failures (1+ failures))
             (message \"Block %d (line %d): FAILED — %s\n  First 100 chars: %.100s\"
                      block-num line
                      (error-message-string err) body)))))))
    (message \"Done. %s\" (if (> failures 0)
                              (format \"%d FAILURES\" failures)
                            \"All blocks OK\")))))
" 2>&1
