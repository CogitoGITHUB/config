#!/bin/sh
# Emacs config doctor — splash, boot, and org-prompts checks
set -u
EMACS=emacs
CFG="$HOME/.config/emacs"
LOG="$HOME/emacs-doctor.log"

section() { printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }

: > "$LOG"

section "1. SPLASH MODULE SELF-TEST"
if [ -f "$CFG/.local/cache/splash-test.el" ]; then
  $EMACS --batch -l "$CFG/.local/cache/splash-test.el" 2>&1 | tee -a "$LOG"
else
  echo "skip: $CFG/.local/cache/splash-test.el missing"
fi

section "2. FULL BOOT"
$EMACS --batch -l "$CFG/init.el" --eval '(message "BOOT-OK")' >> "$LOG" 2>&1
if grep -q "BOOT-OK" "$LOG"; then
  echo "BOOT-OK reached — init survived end to end"
else
  echo "BOOT DIED before completion — see below / full log in $LOG"
fi

section "3. ORG-PROMPTS BLOCK TESTS"
FILE="$CFG/modules/manifolding-atlas/infra/capture/org-prompts.org"
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
             (message \"Block %d (line %d): FAILED — %s\"
                      block-num line (error-message-string err)))))))
    (message \"Done. %s\" (if (> failures 0)
                              (format \"%d FAILURES\" failures)
                            \"All blocks OK\")))))
" 2>&1 | tee -a "$LOG"

section "4. SUMMARY (errors from full boot)"
grep -inE "error|FAIL|void|Cannot open" "$LOG" | head -n 20 || echo "(clean)"

printf '\nFull log: %s\n' "$LOG"
