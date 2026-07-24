;;; manifolding-emacs-remote.el --- Fetching remote Org modules -*- lexical-binding: t; -*-

;;; Commentary:

;; Downloads Org files referenced by a local file's #+REMOTE: property
;; — a plist like (:repo "user/repo" :file "path/to.org" :branch "main")
;; — from raw.githubusercontent.com, caching under
;; `manifolding-emacs-remote-org-directory'.

;;; Code:

(require 'url)
(require 'manifolding-emacs-vars)
(require 'manifolding-emacs-errors)
(require 'manifolding-emacs-org-parse)

(defun manifolding-emacs-remote-plist-to-org-file (remote-file-plist)
  (file-name-concat (file-name-as-directory (expand-file-name manifolding-emacs-remote-org-directory))
                     (format "%s" (plist-get remote-file-plist :repo))
                     (format "%s" (plist-get remote-file-plist :file))))

(defun manifolding-emacs-remote-plist-to-output-file (remote-file-plist)
  (file-name-concat (file-name-as-directory (expand-file-name manifolding-emacs-remote-output-directory))
                     (format "%s" (plist-get remote-file-plist :repo))
                     (concat (file-name-sans-extension (format "%s" (plist-get remote-file-plist :file))) ".el")))

(defun manifolding-emacs--url-retrieve-callback (status remote-file-plist)
  (if (plist-get status :error)
      (manifolding-emacs-record-error
       :level 'remote
       :file (format "%s/%s" (plist-get remote-file-plist :repo) (plist-get remote-file-plist :file))
       :message (format "download failed: %s" (car (last (plist-get status :error)))))
    (goto-char url-http-end-of-headers)
    (let ((response-body (buffer-substring-no-properties (point) (point-max)))
          (file-path (manifolding-emacs-remote-plist-to-org-file remote-file-plist)))
      (make-directory (file-name-directory file-path) t)
      (with-temp-file file-path (insert response-body)))))

(defun manifolding-emacs-pull-remote-file (remote-file-plist)
  "Download REMOTE-FILE-PLIST's file if missing or if a refresh is forced."
  (when (or (not (file-exists-p (manifolding-emacs-remote-plist-to-org-file remote-file-plist)))
            manifolding-emacs-force-download)
    (message "manifolding-emacs: downloading %s:%s"
             (plist-get remote-file-plist :repo) (plist-get remote-file-plist :file))
    (let ((repo (plist-get remote-file-plist :repo))
          (branch (or (plist-get remote-file-plist :branch) "master"))
          (file (plist-get remote-file-plist :file)))
      (url-retrieve (format "https://raw.githubusercontent.com/%s/refs/heads/%s/%s" repo branch file)
                     #'manifolding-emacs--url-retrieve-callback (list remote-file-plist)))))

(defun manifolding-emacs-download-all-remote-files ()
  "Force re-download of every #+REMOTE: file in the local Org directory."
  (interactive)
  (let ((manifolding-emacs-force-download t))
    (dolist (file (manifolding-emacs-get-files "^[^#]*\\.org$" (manifolding-emacs-get-org-directory)))
      (when-let* ((remote-file-plist (manifolding-emacs-file-remote file)))
        (manifolding-emacs-pull-remote-file remote-file-plist)))))

(provide 'manifolding-emacs-remote)
;;; manifolding-emacs-remote.el ends here
