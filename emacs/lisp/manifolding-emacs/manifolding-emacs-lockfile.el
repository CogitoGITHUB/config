;;; manifolding-emacs-lockfile.el --- straight.el profile/lockfile helpers -*- lexical-binding: t; -*-

;;; Commentary:

;; Thin wrappers around straight.el's own freeze/thaw machinery, plus
;; visibility into which #+PROFILE: each module declares.  Version
;; pinning itself is straight's job; this file just makes sure
;; manifolding-emacs-compiler.el binds `straight-current-profile'
;; correctly per file, and gives you commands to freeze/thaw/inspect.

;;; Code:

(require 'manifolding-emacs-vars)
(require 'manifolding-emacs-errors)
(require 'manifolding-emacs-org-parse)

(declare-function straight-freeze-versions "straight")
(declare-function straight-thaw-versions "straight")

(defcustom manifolding-emacs-freeze-after-clean-boot nil
  "If non-nil, run `straight-freeze-versions' at the end of
`manifolding-emacs-boot', but only when that boot recorded zero
errors.  Off by default: freezing is a deliberate act, not something
that should happen silently just because nothing broke today."
  :type 'boolean :group 'manifolding-emacs)

(defun manifolding-emacs-freeze-versions ()
  "Freeze package versions for all configured straight profiles."
  (interactive)
  (if (not (fboundp 'straight-freeze-versions))
      (user-error "straight.el is not loaded")
    (when (yes-or-no-p "Freeze package versions for all straight profiles? ")
      (straight-freeze-versions)
      (message "manifolding-emacs: froze package versions"))))

(defun manifolding-emacs-thaw-versions ()
  "Thaw (restore) package versions from the straight lockfiles."
  (interactive)
  (if (not (fboundp 'straight-thaw-versions))
      (user-error "straight.el is not loaded")
    (when (yes-or-no-p "Thaw package versions from lockfiles? This can downgrade packages. ")
      (straight-thaw-versions)
      (message "manifolding-emacs: thawed package versions"))))

(defun manifolding-emacs-maybe-freeze-on-clean-boot ()
  "Call `straight-freeze-versions' if
`manifolding-emacs-freeze-after-clean-boot' is set and this boot
recorded zero errors.  Call once, at the very end of
`manifolding-emacs-boot'."
  (when (and manifolding-emacs-freeze-after-clean-boot
             (fboundp 'straight-freeze-versions)
             (null (manifolding-emacs-errors-list)))
    (straight-freeze-versions)
    (message "manifolding-emacs: boot was clean, froze package versions")))

(defun manifolding-emacs-list-profiles ()
  "Show which #+PROFILE: each module file declares, in a report buffer."
  (interactive)
  (let ((files (manifolding-emacs-get-files "^[^#]*\\.org$" (manifolding-emacs-get-org-directory)))
        (buf (get-buffer-create "*manifolding-emacs profiles*")))
    (with-current-buffer buf
      (erase-buffer)
      (insert "Profile  ->  File\n" (make-string 40 ?-) "\n")
      (dolist (file files)
        (insert (format "%-8s %s\n" (or (manifolding-emacs-file-profile file) "(default)") file))))
    (display-buffer buf)))

(provide 'manifolding-emacs-lockfile)
;;; manifolding-emacs-lockfile.el ends here
