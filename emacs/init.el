;;; init.el --- STATIC SEED: tangles + loads Manifolding-Emacs-Foundation -*- lexical-binding: t -*-
;;
;; ┌─────────────────────────────────────────────────────────────┐
;; │  THIS FILE IS STATIC.  Never add configuration here.        │
;; │                                                             │
;; │  Single source of truth:                                    │
;; │    Manifolding-Emacs/Manifolding-Emacs-Foundation.org       │
;; │      · auto-tangled on save   (org-auto-tangle)             │
;; │      · re-tangled at startup  (below)                       │
;; │      → produces early-init.el + foundation-init.el          │
;; └─────────────────────────────────────────────────────────────┘

(setq debug-on-error t)

(let ((org-build (locate-user-emacs-file "straight/build/org")))
  (when (file-directory-p org-build)
    (add-to-list 'load-path org-build)))

(require 'org)

(defvar manifold--foundation-org
  (locate-user-emacs-file
   "Manifolding-Emacs/Manifolding-Emacs-Foundation.org"))
(defvar manifold--foundation-init
  (locate-user-emacs-file "Manifolding-Emacs/foundation-init.el"))

(defun manifold/tangle-foundation ()
  "Tangle the foundation.  Uses only built-in Org — no deps."
  (require 'ob-core)
  (org-babel-tangle-file manifold--foundation-org))

;; Startup tangle — belt and suspenders alongside org-auto-tangle.
(if (file-exists-p manifold--foundation-org)
    (with-demoted-errors "[foundation] startup tangle failed: %s"
      (manifold/tangle-foundation))
  (message "[foundation] %s missing; using last generated config"
           (file-name-nondirectory manifold--foundation-org)))

;; Load the freshly generated (or last known good) configuration.
(if (file-exists-p manifold--foundation-init)
    (load manifold--foundation-init nil 'nomessage)
  (warn "[foundation] %s not found — bare editor this session"
        manifold--foundation-init))

;;; init.el ends here