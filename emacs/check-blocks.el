;;; check-blocks.el --- Check paren balance of every src block in an org file -*- lexical-binding: t; -*-
;; Usage:
;;   emacs --batch --load ~/.config/emacs/check-blocks.el --eval '(check-blocks-all)'
;;   emacs --batch --load ~/.config/emacs/check-blocks.el --eval '(check-blocks "modules/manifolding-atlas/infra/capture/infrastructure.org")'

(require 'org)

(defun cb--verify (code)
  "Verify CODE holds whole balanced forms.
Return nil if OK, else (REL-LINE . DESCRIPTION) of first failure."
  (with-temp-buffer
    (insert code)
    (goto-char (point-min))
    (catch 'result
      (let (last-top-start)
        (while t
          (skip-chars-forward " \t\r\n")
          (if (eobp) (throw 'result nil)
            (setq last-top-start (line-number-at-pos))
            (condition-case err
                (read (current-buffer))
              (end-of-file
               (throw 'result
                      (cons last-top-start
                            (format "UNBALANCED: form starting at code line %d never closes"
                                    last-top-start))))
              (invalid-read-syntax
               (throw 'result
                      (cons (line-number-at-pos (cadr err))
                            (format "STRAY CLOSER at code line %d (after form starting at code line %d)"
                                    (line-number-at-pos (cadr err)) last-top-start))))))))))

(defun cb--check-file (path)
  "Report bad src blocks in org PATH with absolute file lines."
  (let ((bad 0) (total 0))
    (with-temp-buffer
      (insert-file-contents path)
      (org-mode)
      (org-element-map (org-element-parse-buffer) 'src-block
        (lambda (b)
          (setq total (1+ total))
          (let* ((code (org-element-property :value b))
                 (begin (org-element-property :begin b))
                 (block-line (line-number-at-pos begin)))
            (when-let ((fail (cb--verify code)))
              (setq bad (1+ bad))
              (message "BAD  ~file line %d in %s => %s"
                       (+ block-line (car fail)) path (cdr fail)))))))
    (message "%s => %d blocks, %d bad" path total bad)))

(defun check-blocks (file)
  "Check FILE relative to ~/.config/emacs."
  (cb--check-file (expand-file-name file "~/.config/emacs")))

(defun check-blocks-all ()
  "Check the capture machinery."
  (check-blocks "modules/manifolding-atlas/infra/capture/org-prompts.org")
  (check-blocks "modules/manifolding-atlas/infra/capture/infrastructure.org")
  (check-blocks "modules/manifolding-atlas/infra/capture/entry-points.org")
  (check-blocks "modules/manifolding-atlas/infra/capture/prompt-engine.org")
  (check-blocks "modules/manifolding-atlas/infra/capture/note-creation.org"))
