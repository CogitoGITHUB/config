;;; manifolding-mind-map.el --- User Interface for Org-roam -*- coding: utf-8; lexical-binding: t; -*-

;; Copyright © 2021 Kirill Rogovoy, Thomas F. K. Jorna

;; author: Kirill Rogovoy, Thomas Jorna
;; Keywords: files outlines
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (vulpea "2.4.0") (simple-httpd "20191103.1446") (websocket "1.13"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;;  Org-roam-ui provides a web interface for navigating around notes created
;;  within Org-roam.
;;
;;; Code:
;;;; Dependencies
(require 'json)
(require 'simple-httpd)
(require 'websocket)
(require 'org-id)
(require 'cl-lib)
(require 'vulpea)
(require 'ox-html)

(defgroup manifolding-mind-map nil
  "Mind map for vulpea notes."
  :group 'vulpea
  :prefix "manifolding-mind-map-")

(defvar manifolding-mind-map-root-dir
  (concat (file-name-directory
           (expand-file-name (or
                    load-file-name
                    buffer-file-name)))
          ".")
  "Root directory of the manifolding-mind-map project.")

(defvar manifolding-mind-map-app-build-dir
  (expand-file-name "./out/" manifolding-mind-map-root-dir)
  "Directory containing manifolding-mind-map's web build.")

;; TODO: make into defcustom
(defvar manifolding-mind-map-port
  35901
  "Port to serve the manifolding-mind-map interface.")

(defcustom manifolding-mind-map-sync-theme t
  "If true, sync your current Emacs theme with `manifolding-mind-map'.
Works best with doom-themes.
Ignored if a custom theme is provied for variable 'manifolding-mind-map-custom-theme'."
  :group 'manifolding-mind-map
  :type 'boolean)

(defcustom manifolding-mind-map-custom-theme nil
  "Custom theme for `manifolding-mind-map'.
Blocks 'manifolding-mind-map-sync-theme from syncing your current theme,
instead sync this theme.
Provide a list of cons with the following values:
bg, bg-alt, fg, fg-alt, red, orange, yellow, green, cyan, blue, violet, magenta.
E.g. '((bg . \"#1E2029\")
\(bg-alt . \"#282a36\")
\(fg . \"#f8f8f2\")
\(fg-alt . \"#6272a\")
\(red . \"#ff5555\")
\(orange . \"#f1fa8c\")
\(yellow .\"#ffb86c\")
\(green . \"#50fa7b\")
\(cyan . \"#8be9fd\")
\(blue . \"#ff79c6\")
\(violet . \"#8be9fd\")
\(magenta . \"#bd93f9\"))."
  :group 'manifolding-mind-map
  :type 'list)

(defcustom manifolding-mind-map-follow t
  "If true, `manifolding-mind-map' will follow you around in the graph."
  :group 'manifolding-mind-map
  :type 'boolean)

(defcustom manifolding-mind-map-update-on-save t
  "If true, `manifolding-mind-map' will send new data when you save a note buffer.
This can lead to some jank."
  :group 'manifolding-mind-map
  :type 'boolean)

(defcustom manifolding-mind-map-open-on-start t
  "Whether to open your default browser when `manifolding-mind-map' launces."
  :group 'manifolding-mind-map
  :type 'boolean)

(defcustom manifolding-mind-map-find-ref-title t
  "Should `manifolding-mind-map' use `org-roam-bibtex' to find a reference's title?"
  :group 'manifolding-mind-map
  :type 'boolean)

(defcustom manifolding-mind-map-retitle-ref-nodes t
  "Should `manifolding-mind-map' use `org-roam-bibtex' try to retitle reference nodes?"
  :group 'manifolding-mind-map
  :type 'boolean)

(defcustom manifolding-mind-map-ref-title-template
  "%^{author-abbrev} (%^{year}) %^{title}"
  "A template for title creation, used for references without associated nodes.

This uses `orb--pre-expand-template' under the hood and therefore only org-style
capture `%^{...}' are supported."
  :group 'manifolding-mind-map
  :type 'string)

(defcustom manifolding-mind-map-browser-function #'browse-url
  "When non-nil launch manifolding-mind-map with a different browser function.
Takes a function name, such as #'browse-url-chromium.
Defaults to #'browse-url."
  :group 'manifolding-mind-map
  :type 'function)

;;Hooks

(defcustom manifolding-mind-map-before-open-node-functions nil
  "Functions to run before a node is opened through manifolding-mind-map.
Take ID as string as sole argument."
  :group 'manifolding-mind-map
  :type 'hook)

(defcustom manifolding-mind-map-after-open-node-functions nil
  "Functions to run after a node is opened through manifolding-mind-map.
Take ID as string as sole argument."
  :group 'manifolding-mind-map
  :type 'hook)

(defcustom manifolding-mind-map-latex-macros nil
  "Alist of LaTeX macros to be passed to manifolding-mind-map.
Format as, i.e. with double backslashes for a single backslash:
'((\"\\macro\".\"\\something{#1}\"))"
  :group 'manifolding-mind-map
  :type 'alist)

(defcustom manifolding-mind-map-physics
  '((enabled . t)
    (charge . -700)
    (collision . t)
    (collisionStrength . 20)
    (centering . t)
    (centeringStrength . 0.2)
    (linkStrength . 0.3)
    (linkIts . 1)
    (alphaDecay . 0.05)
    (alphaTarget . 0)
    (alphaMin . 0)
    (velocityDecay . 0.25)
    (gravity . 0.3)
    (gravityOn . t)
    (gravityLocal . nil))
  "Physics simulation settings for the mind-map graph.
Alist with keys: enabled, charge, collision, collisionStrength,
centering, centeringStrength, linkStrength, linkIts, alphaDecay,
alphaTarget, alphaMin, velocityDecay, gravity, gravityOn, gravityLocal."
  :group 'manifolding-mind-map
  :type 'list)

(defcustom manifolding-mind-map-filter
  '((orphans . nil)
    (dailies . nil)
    (parent . "heading")
    (filelessCites . nil)
    (tagsBlacklist . [])
    (tagsWhitelist . [])
    (dirsBlocklist . [])
    (dirsAllowlist . [])
    (bad . t)
    (nodes . [])
    (links . [])
    (date . [])
    (noter . t))
  "Filter settings for which nodes/links appear in the graph.
Alist with keys: orphans, dailies, parent, filelessCites,
tagsBlacklist, tagsWhitelist, dirsBlocklist, dirsAllowlist,
bad, nodes, links, date, noter."
  :group 'manifolding-mind-map
  :type 'list)

(defcustom manifolding-mind-map-visuals
  '((particles . nil)
    (particlesNumber . 0)
    (particlesWidth . 4)
    (arrows . nil)
    (arrowsLength . 1)
    (arrowsPos . 0.5)
    (arrowsColor . "")
    (linkOpacity . 0.8)
    (linkWidth . 1)
    (nodeRel . 3)
    (nodeOpacity . 1)
    (nodeResolution . 12)
    (labels . 2)
    (labelScale . 1.5)
    (labelFontSize . 10)
    (labelLength . 40)
    (labelWordWrap . 25)
    (labelLineSpace . 1)
    (labelDynamicDegree . 8)
    (labelDynamicStrength . 0.5)
    (highlight . t)
    (highlightNodeSize . 1.1)
    (highlightLinkSize . 0.7)
    (highlightFade . 0.8)
    (highlightAnim . t)
    (animationSpeed . 360)
    (algorithmName . "CircularOut")
    (linkColorScheme . "base4")
    (nodeColorScheme . ["red" "base5" "yellow" "green" "cyan" "blue" "magenta" "violet" "orange"])
    (nodeHighlight . "blue")
    (linkHighlight . "blue")
    (backgroundColor . "bg")
    (emacsNodeColor . "fg")
    (labelTextColor . "fg")
    (labelBackgroundColor . "")
    (labelBackgroundOpacity . 0.7)
    (citeDashes . t)
    (citeDashLength . 35)
    (citeGapLength . 15)
    (citeLinkColor . "base6")
    (citeLinkHighlightColor . "")
    (citeNodeColor . "fg")
    (refDashes . t)
    (refDashLength . 35)
    (refGapLength . 15)
    (refLinkColor . "base6")
    (refLinkHighlightColor . "")
    (refNodeColor . "fg")
    (nodeSizeLinks . 0.5)
    (nodeZoomSize . 1.2))
  "Visual appearance settings for the mind-map graph.
Alist with keys: particles, particlesNumber, particlesWidth,
arrows, arrowsLength, arrowsPos, arrowsColor, linkOpacity,
linkWidth, nodeRel, nodeOpacity, nodeResolution, labels,
labelScale, labelFontSize, labelLength, labelWordWrap,
labelLineSpace, labelDynamicDegree, labelDynamicStrength,
highlight, highlightNodeSize, highlightLinkSize, highlightFade,
highlightAnim, animationSpeed, algorithmName, linkColorScheme,
nodeColorScheme, nodeHighlight, linkHighlight, backgroundColor,
emacsNodeColor, labelTextColor, labelBackgroundColor,
labelBackgroundOpacity, citeDashes, citeDashLength,
citeGapLength, citeLinkColor, citeLinkHighlightColor, citeNodeColor,
refDashes, refDashLength, refGapLength, refLinkColor,
refLinkHighlightColor, refNodeColor, nodeSizeLinks, nodeZoomSize."
  :group 'manifolding-mind-map
  :type 'list)

(defcustom manifolding-mind-map-coloring
  '((method . "degree"))
  "Node coloring settings.
Alist with key: method (\"degree\" or \"community\")."
  :group 'manifolding-mind-map
  :type 'list)

(defcustom manifolding-mind-map-behavior
  '((follow . "zoom")
    (localSame . "add")
    (zoomPadding . 200)
    (zoomSpeed . 2000))
  "Behavior settings for graph interaction.
Alist with keys: follow, localSame, zoomPadding, zoomSpeed."
  :group 'manifolding-mind-map
  :type 'list)

(defcustom manifolding-mind-map-mouse
  '((highlight . "hover")
    (local . "double")
    (follow . "never")
    (context . "right")
    (preview . "click")
    (backgroundExitsLocal . nil))
  "Mouse interaction settings.
Alist with keys: highlight, local, follow, context, preview,
backgroundExitsLocal."
  :group 'manifolding-mind-map
  :type 'list)

(defcustom manifolding-mind-map-local
  '((neighbors . 1))
  "Local graph view settings.
Alist with key: neighbors."
  :group 'manifolding-mind-map
  :type 'list)

;; Internal vars

(defvar manifolding-mind-map--ws-current-node nil
  "Var to keep track of which node you are looking at.")

(defvar manifolding-mind-map-ws-socket nil
  "The websocket for manifolding-mind-map.")

(defvar manifolding-mind-map--window nil
  "The window for displaying nodes opened from within ORUI.
This is mostly to prevent issues with EXWM and the Webkit browser.")

(defvar manifolding-mind-map-ws-server nil
  "The websocket server for manifolding-mind-map.")

;;;; Color utilities

(defun manifolding-mind-map--blend (c1 c2 ratio)
  "Blend two RGB lists C1 and C2 by RATIO (0-1)."
  (list (+ (* (nth 0 c1) (- 1 ratio)) (* (nth 0 c2) ratio))
        (+ (* (nth 1 c1) (- 1 ratio)) (* (nth 1 c2) ratio))
        (+ (* (nth 2 c1) (- 1 ratio)) (* (nth 2 c2) ratio))))

(defun manifolding-mind-map--interpolate-color (color1 color2 ratio)
  "Interpolate between COLOR1 and COLOR2 at RATIO (0-1)."
  (let* ((rgb1 (color-name-to-rgb color1))
         (rgb2 (color-name-to-rgb color2))
         (blended (manifolding-mind-map--blend rgb1 rgb2 ratio)))
    (apply #'format "#%02x%02x%02x"
           (cl-mapcar (lambda (v) (round (* v 255))) blended))))

;;;###autoload
(define-minor-mode
  manifolding-mind-map-mode
  "Enable manifolding-mind-map.
This serves the web-build and API over HTTP."
  :lighter " manifolding-mind-map"
  :global t
  :group 'manifolding-mind-map
  :init-value nil
  (cond
   (manifolding-mind-map-mode
   ;;; check if the default keywords actually exist on `orb-preformat-keywords'
   ;;; else add them
    (setq-local httpd-port manifolding-mind-map-port)
    (setq-local httpd-host "0.0.0.0")
    (setq httpd-root manifolding-mind-map-app-build-dir)
    (httpd-start)
    (setq manifolding-mind-map-ws-server
           (websocket-server
            35903
            :host "0.0.0.0"
            :on-open #'manifolding-mind-map--ws-on-open
           :on-message #'manifolding-mind-map--ws-on-message
           :on-close #'manifolding-mind-map--ws-on-close))
    (when manifolding-mind-map-open-on-start (manifolding-mind-map-open)))
   (t
    (progn
      (websocket-server-close manifolding-mind-map-ws-server)
      (httpd-stop)
      (remove-hook 'after-save-hook #'manifolding-mind-map--on-save)
      (manifolding-mind-map-follow-mode -1)))))

(defun manifolding-mind-map--ws-on-open (ws)
  "Open the websocket WS to manifolding-mind-map and send initial data."
  (progn
    (setq manifolding-mind-map-ws-socket ws)
    (condition-case err
        (progn
          (manifolding-mind-map--send-variables manifolding-mind-map-ws-socket)
          (message "send-variables OK"))
      (error (message "send-variables ERROR: %S %S" (car err) (cdr err))))
    (condition-case err
        (progn
          (manifolding-mind-map--send-visuals manifolding-mind-map-ws-socket)
          (message "send-visuals OK"))
      (error (message "send-visuals ERROR: %S %S" (car err) (cdr err))))
    (condition-case err
        (progn
          (manifolding-mind-map--send-graphdata)
          (message "send-graphdata OK"))
      (error (message "send-graphdata ERROR: %S %S" (car err) (cdr err))))
    (when manifolding-mind-map-update-on-save
      (add-hook 'after-save-hook #'manifolding-mind-map--on-save))
    (message "Connection established with manifolding-mind-map")
    (when manifolding-mind-map-follow
      (manifolding-mind-map-follow-mode 1))))

(defun manifolding-mind-map--ws-on-message (_ws frame)
  "Functions to run when the manifolding-mind-map server receives a message.
Takes _WS and FRAME as arguments."
  (let* ((msg (json-parse-string
               (websocket-frame-text frame) :object-type 'alist))
         (command (alist-get 'command msg))
         (data (alist-get 'data msg)))
    (cond ((string= command "open")
           (manifolding-mind-map--on-msg-open-node data))
          ((string= command "delete")
           (manifolding-mind-map--on-msg-delete-node data))
          ((string= command "create")
           (manifolding-mind-map--on-msg-create-node data))
          (t
           (message
            "Something went wrong when receiving a message from manifolding-mind-map")))))

(defun manifolding-mind-map--on-msg-open-node (data)
  "Open a node when receiving DATA from the websocket."
  (let* ((id (alist-get 'id data))
          (note (vulpea-db-get-by-id id))
          (pos (vulpea-note-pos note))
          (buf (find-file-noselect (vulpea-note-path note))))
    (run-hook-with-args 'manifolding-mind-map-before-open-node-functions id)
    (unless (window-live-p manifolding-mind-map--window)
      (if-let ((windows (window-list))
               (notes-dir (my/notes-directory))
               (or-windows (seq-filter
                            (lambda (window)
                              (when-let ((bf (buffer-file-name
                                              (window-buffer window))))
                                (string-prefix-p notes-dir bf)))
                            windows))
               (newest-window (car
                               (seq-sort-by
                                #'window-use-time #'> or-windows))))
          (setq manifolding-mind-map--window newest-window)
        (split-window-horizontally)
        (setq manifolding-mind-map--window (frame-selected-window))))
    (set-window-buffer manifolding-mind-map--window buf)
    (select-window manifolding-mind-map--window)
    (goto-char pos)
    (run-hook-with-args 'manifolding-mind-map-after-open-node-functions id)))

(defun manifolding-mind-map--on-msg-delete-node (data)
  "Delete a node when receiving DATA from the websocket.

TODO: Be able to delete individual nodes."
  (let ((file (alist-get 'file data)))
    (message "Deleted %s" file)
    (delete-file file)
    (manifolding-mind-map--send-graphdata)))

(defun manifolding-mind-map--on-msg-create-node (data)
  "Create a node when receiving DATA from the websocket."
  (let ((title (alist-get 'title data)))
    (when title
      (vulpea-create title))))

(defun manifolding-mind-map--ws-on-close (_websocket)
  "What to do when _WEBSOCKET to manifolding-mind-map is closed."
  (remove-hook 'after-save-hook #'manifolding-mind-map--on-save)
  (manifolding-mind-map-follow-mode -1)
  (message "Connection with manifolding-mind-map closed."))

(defun manifolding-mind-map--get-text (id)
  "Retrieve the text from vulpea note ID."
  (let ((note (vulpea-db-get-by-id id)))
    (when note
      (vulpea-utils-with-note note
        (when (> (vulpea-note-level note) 0)
          (goto-char (vulpea-note-pos note))
          (org-narrow-to-element))
        (buffer-substring-no-properties (buffer-end -1) (buffer-end 1))))))

(defun manifolding-mind-map--get-html (id)
  "Retrieve the ox-html export of the note identified by ID."
  (let* ((note (vulpea-db-get-by-id id))
         (level (vulpea-note-level note)))
    (when note
      (vulpea-utils-with-note note
        (let ((org-html-with-toc nil)
              (org-export-with-section-numbers nil)
              (org-export-headline-levels 8))
          (if (> level 0)
              (progn
                (goto-char (vulpea-note-pos note))
                (org-export-as 'html nil t nil 'body-only nil))
            (org-export-as 'html nil nil nil 'body-only nil)))))))

(defun manifolding-mind-map--send-text (id ws)
  "Send the text from org-node ID through the websocket WS."
  (let ((text (manifolding-mind-map--get-text id)))
    (websocket-send-text ws
                         (json-encode
                          `((type . "orgText")
                            (data . ,text))))))

(defservlet* node/:id text/plain ()
  "Servlet for accessing node content."
  (insert (manifolding-mind-map--get-text (org-link-decode id)))
  (httpd-send-header t "text/plain" 200 :Access-Control-Allow-Origin "*"))

(defservlet* node/:id/html text/html ()
  "Servlet for accessing node content as HTML."
  (insert (manifolding-mind-map--get-html (org-link-decode id)))
  (httpd-send-header t "text/html" 200 :Access-Control-Allow-Origin "*"))

(defservlet* img/:file text/plain ()
  "Servlet for accessing images found in note files."
  (progn
    (httpd-send-file t (org-link-decode file))
    (httpd-send-header t "text/plain" 200 :Access-Control-Allow-Origin "*")))

(defun manifolding-mind-map--on-save ()
  "Send graphdata on saving a vulpea buffer.

TODO: Make this only send the changes to the graph data, not the complete graph."
  (when (and buffer-file-name
             (string-prefix-p (my/notes-directory) buffer-file-name))
    (manifolding-mind-map--send-variables manifolding-mind-map-ws-socket)
    (manifolding-mind-map--send-graphdata)))

(defun manifolding-mind-map--check-orb-keywords ()
  "Check if the default keywords are in `orb-preformat-keywords', if not, add them."
  (when (and manifolding-mind-map-retitle-ref-nodes (boundp 'orb-preformat-keywords))
    (dolist (keyword '("author-abbrev" "year" "title"))
      (unless (seq-contains-p orb-preformat-keywords keyword)
        (setq orb-preformat-keywords
              (append orb-preformat-keywords (list keyword)))))))

(defun manifolding-mind-map--find-ref-title (ref)
  "Find the title of the bibtex entry keyed by `REF'.

Requires `org-roam-bibtex' and `bibtex-completion' (a dependency of `orb') to be
loaded. Returns `ref' if an entry could not be found."
  (if (and manifolding-mind-map-find-ref-title
           (fboundp 'bibtex-completion-get-entry)
           (fboundp 'orb--pre-expand-template)
           (boundp 'orb-preformat-keywords))
      (if-let ((entry (bibtex-completion-get-entry ref))
               (orb-preformat-keywords
                (append orb-preformat-keywords
                        '("author-abbrev" "year" "title"))))
          ;; Create a fake capture template list, only the actual capture at 3
          ;; matters. Interpolate the bibtex entries, and extract the filled
          ;; template from the return value.
          (nth 3 (orb--pre-expand-template
                  `("" "" plain ,manifolding-mind-map-ref-title-template) entry))
        ref)
    ref))

(defun manifolding-mind-map--replace-nth (el n lst)
  "Non-destructively replace the `N'th element of `LST' with `EL'."
  (let ((head (butlast lst (- (length lst) n)))
        (tail (nthcdr (+ n 1) lst)))
    (append head (list el) tail)))

(defun manifolding-mind-map--citekey-to-ref (citekey)
  "Convert a CITEKEY property (most likely with a `cite:' prefix) to just a key.

This method is mostly taken from `org-roam-bibtex'
see https://github.com/org-roam/org-roam-bibtex/blob/919ec8d837a7a3bd25232bdba17a0208efaefb2a/orb-utils.el#L289
but is has been adapted to operate on a sting instead of a node. Requires
`org-ref' to be loaded. Returns the `key' or nil if the format does not match
the `org-ref-cite-re'"
  (if-let ((boundp 'org-ref-cite-re)
           (citekey-list (split-string-and-unquote citekey)))
      (catch 'found
        (dolist (c citekey-list)
          (when (string-match org-ref-cite-re c)
            (throw 'found (match-string 2 c)))))))

(defun manifolding-mind-map--retitle-node (node)
  "Replace the title of citation NODE with associated notes.

A new title is created using information from the bibliography and formatted
according to `manifolding-mind-map-ref-title-template'.

Returns the node with an updated title if the current node is a reference node
and the key was found in the bibliography, otherwise the node is returned
unchanged."
  (if-let* (manifolding-mind-map-retitle-ref-nodes
            (orcr (boundp 'org-ref-cite-re))
            (citekey (cdr (assoc "ROAM_REFS" (nth 6 node))))
            (ref (manifolding-mind-map--citekey-to-ref citekey))
            (title (manifolding-mind-map--find-ref-title ref)))
      (manifolding-mind-map--replace-nth title 2 node)
    node))

(defun manifolding-mind-map--create-fake-node (ref)
  "Create a fake node for REF without a source note."
  (list
   ref
   ref
   (manifolding-mind-map--find-ref-title ref)
   0
   0
   'nil
   `(("ROAM_REFS" . ,(format "cite:%s" ref))
     ("FILELESS" . t))
   'nil))

(defun manifolding-mind-map--send-graphdata ()
  "Get vulpea data, make JSON, send through websocket."
  (let* ((links-db-rows (seq-concatenate
                          'list
                          (manifolding-mind-map--separate-ref-links
                           (manifolding-mind-map--get-cites))
                          (manifolding-mind-map--get-links)
                          (manifolding-mind-map--get-transclude-links)))
         (links-with-empty-refs (manifolding-mind-map--filter-citations links-db-rows))
         (empty-refs (delete-dups (seq-map
                                   (lambda (link)
                                     (nth 1 link))
                                   links-with-empty-refs)))
         (nodes-db-rows (manifolding-mind-map--get-nodes))
         (fake-nodes (seq-map #'manifolding-mind-map--create-fake-node empty-refs))
         (retitled-nodes-db-rows (if manifolding-mind-map-retitle-ref-nodes
                                    (seq-map #'manifolding-mind-map--retitle-node
                                             nodes-db-rows)
                                  nodes-db-rows))
         (complete-nodes-db-rows (append retitled-nodes-db-rows fake-nodes))
         (response `((nodes . ,(mapcar
                                #'manifolding-mind-map--row-to-alist
                                complete-nodes-db-rows))
                     (links . ,(mapcar
                                (apply-partially
                                 #'manifolding-mind-map-sql-to-alist
                                 '(source target type))
                                links-db-rows))
                     (tags . ,(vulpea-db-query-tags)))))
    (websocket-send-text manifolding-mind-map-ws-socket (json-encode
                                                `((type . "graphdata")
                                                  (data . ,response))))))

(defun manifolding-mind-map--row-to-alist (row)
  "Convert a node ROW to an alist for JSON encoding.
Row format: (id path title level pos olp-string properties tags)"
  (let ((keys '(id file title level pos olp properties tags)))
    (cl-mapcar (lambda (k v) (cons k v)) keys row)))


(defun manifolding-mind-map--filter-citations (links)
  "Filter out the citations from LINKS."
  (seq-filter
   (lambda (link)
     (string-match-p "cite" (nth 2 link)))
   links))

(defun manifolding-mind-map--get-nodes ()
  "Get all notes as rows.
Row format: (id path title level pos olp-string properties tags)"
  (mapcar #'manifolding-mind-map--note-to-row
          (vulpea-db-query)))

(defun manifolding-mind-map--note-to-row (note)
  "Convert a vulpea-note NOTE to the row format.
Row format: (id path title level pos olp-string properties tags)"
  (list
   (vulpea-note-id note)
   (vulpea-note-path note)
   (vulpea-note-title note)
   (vulpea-note-level note)
   (vulpea-note-pos note)
   (string-join (vulpea-note-outline-path note) " / ")
   (vulpea-note-properties note)
   (or (vulpea-note-tags note) '())))

(defun manifolding-mind-map--get-links ()
  "Get id-type links as rows.
Row format: (source dest type)"
  (seq-map
   #'manifolding-mind-map--link-plist-to-row
   (seq-filter
    (lambda (l) (string= (plist-get l :type) "id"))
    (vulpea-db-query-links))))

(defun manifolding-mind-map--get-transclude-links ()
  "Get transclusion links from the transclude_links table.
Row format: (source dest type)"
  (ignore-errors
    (let* ((rows (emacsql (vulpea-db)
                          [:select [source dest] :from transclude_links]))
           (result (mapcar
                    (lambda (row)
                      (list (car row) (cadr row) "transclude"))
                    rows)))
      (message "transclude-links: %d rows" (length result))
      result)))

(defun manifolding-mind-map--get-cites ()
  "Get cite-type links as rows.
Row format: (source dest type)"
  (seq-map
   #'manifolding-mind-map--link-plist-to-row
   (seq-filter
    (lambda (l) (string-match-p "cite" (plist-get l :type)))
    (vulpea-db-query-links))))

(defun manifolding-mind-map--link-plist-to-row (link)
  "Convert a vulpea link plist LINK to row format.
Row format: (source dest type)"
  (list
   (plist-get link :source)
   (plist-get link :dest)
   (plist-get link :type)))

(defun manifolding-mind-map--separate-ref-links (links)
  "Create separate entries for cite LINKS.
Convert cite links to ref links when the dest matches an existing note,
otherwise keep as cite type."
  (seq-map
   (lambda (link)
     (pcase-let ((`(,source ,dest ,type) link))
       (if (vulpea-db-get-by-id dest)
           (list source dest "ref")
         (list source dest type))))
   links))

(defun manifolding-mind-map--update-current-node ()
  "Send the current node data to the web-socket."
  (when (and (websocket-openp manifolding-mind-map-ws-socket)
             buffer-file-name
             (string-prefix-p (my/notes-directory) buffer-file-name)
             (buffer-file-name (buffer-base-buffer)))
    (let* ((node (org-id-get)))
      (unless (string= manifolding-mind-map--ws-current-node node)
        (setq manifolding-mind-map--ws-current-node node)
        (websocket-send-text manifolding-mind-map-ws-socket
                             (json-encode `((type . "command")
                                            (data . ((commandName . "follow")
                                                     (id . ,node))))))))))


(defun manifolding-mind-map--update-theme ()
  "Extract current Emacs theme colors into a palette alist."
  (if (boundp 'doom-themes--colors)
      (let* ((colors (butlast doom-themes--colors
                              (- (length doom-themes--colors) 25)))
             doom-theme)
        (dolist (color colors)
          (push (cons (car color) (car (cdr color))) doom-theme))
        doom-theme)
    (manifolding-mind-map-get-theme)))


(defun manifolding-mind-map--send-variables (ws)
  "Send miscellaneous variables through the websocket WS."
  (let ((notes-dir (my/notes-directory))
        (attach-dir (if (boundp 'org-attach-id-dir)
                        org-attach-id-dir
                      (expand-file-name ".attach/" org-directory)))
        (use-inheritance (if (boundp 'org-attach-use-inheritance)
                             org-attach-use-inheritance nil))
        (sub-dirs (manifolding-mind-map-find-subdirectories)))
    (websocket-send-text manifolding-mind-map-ws-socket
                         (json-encode
                          `((type . "variables")
                            (data .
                                  (("subDirs" . ,sub-dirs)
                                   ("dailyDir" . "/dailies")
                                   ("attachDir" . ,attach-dir)
                                   ("useInheritance" . ,use-inheritance)
                                   ("roamDir" . ,notes-dir)
                                   ("katexMacros" . ,manifolding-mind-map-latex-macros))))))))

(defun manifolding-mind-map--send-visuals (ws)
  "Send visual settings from Emacs to the frontend."
  (let* ((theme (condition-case nil
                    (manifolding-mind-map--update-theme)
                  (error (message "Theme extraction failed, using fallback")
                         '((fg . "#000") (bg . "#fff") (bg-alt . "#eee")
                           (fg-alt . "#666") (red . "red") (orange . "orange")
                           (yellow . "yellow") (green . "green") (cyan . "cyan")
                           (blue . "blue") (violet . "purple") (magenta . "magenta")))))
         (msg (json-encode
               `((type . "visuals")
                 (data .
                       ((theme . ,theme)
                        (physics . ,manifolding-mind-map-physics)
                        (filter . ,manifolding-mind-map-filter)
                        (visuals . ,manifolding-mind-map-visuals)
                        (coloring . ,manifolding-mind-map-coloring)
                        (behavior . ,manifolding-mind-map-behavior)
                        (mouse . ,manifolding-mind-map-mouse)
                        (local . ,manifolding-mind-map-local)))))))
    (websocket-send-text ws msg)))

(defun manifolding-mind-map-sql-to-alist (column-names rows)
  "Convert sql result to alist for json encoding.
ROWS is the sql result, while COLUMN-NAMES is the columns to use."
  (let (res)
    (while rows
      ;; I don't know how to get the tags as a simple list, so we post process it
      (if (not (string= (car column-names) "tags"))
          (push (cons (pop column-names) (pop rows)) res)
        (push (cons (pop column-names)
                    (seq-remove
                     (lambda (elt) (string= elt ","))
                     rows))
              res)
        (setq rows nil)))
    res))

(defun manifolding-mind-map-get-theme ()
  "Extract current Emacs theme colors into a standardized palette alist.
Generates base0-base8 gray ramp via interpolation between bg and fg.
Falls back to frame parameters or sensible defaults."
  (let* ((fg (or (face-attribute 'default :foreground nil 'default)
                 (frame-parameter nil 'foreground-color)
                 "#000"))
         (bg (or (face-attribute 'default :background nil 'default)
                 (frame-parameter nil 'background-color)
                 "#fff"))
         (bg-hl (or (and (boundp 'hl-line-face)
                         (face-attribute hl-line-face :background nil 'default))
                    bg)))
         (colors `((bg . ,bg-hl)
                   (bg-alt . ,bg)
                   (fg . ,fg)
                   (fg-alt . ,(or (face-foreground font-lock-comment-face) fg))
                   (red . ,(or (face-foreground 'error) "red"))
                   (orange . ,(or (face-foreground 'warning) "orange"))
                   (yellow . ,(or (face-foreground font-lock-builtin-face) "yellow"))
                   (green . ,(or (face-foreground 'success) "green"))
                   (cyan . ,(or (face-foreground font-lock-constant-face) "cyan"))
                   (blue . ,(or (face-foreground font-lock-keyword-face) "blue"))
                   (violet . ,(or (face-foreground font-lock-constant-face) "purple"))
                   (magenta . ,(or (face-foreground font-lock-preprocessor-face) "magenta")))))
    (cl-loop for i from 0 to 8
             for ratio = (/ (float i) 8.0)
             do (push (cons (intern (format "base%d" i))
                            (manifolding-mind-map--interpolate-color bg fg ratio))
                      colors))
    (nreverse colors))

(defun manifolding-mind-map-find-subdirectories ()
  "Find all the subdirectories in the notes directory.
TODO: Exclude org-attach dirs."
   (seq-filter
    (lambda (file) (and (file-directory-p file) (manifolding-mind-map-allowed-directory-p file)))
    (directory-files-recursively (my/notes-directory)
                                 ".*" t #'manifolding-mind-map-allowed-directory-p)))

(defun manifolding-mind-map-allowed-directory-p (dir)
  "Check whether a DIR should be listed as a filterable dir.
Hides . directories."
  (not (string-match-p "\\(\/\\|\\\\\\)\\..*?"  dir)))

;;;; interactive commands

;;;###autoload
(defun manifolding-mind-map-open ()
  "Ensure `manifolding-mind-map' is running, then open the `manifolding-mind-map' webpage."
  (interactive)
  (unless manifolding-mind-map-mode (manifolding-mind-map-mode))
  (funcall manifolding-mind-map-browser-function
           (format "http://localhost:%d" manifolding-mind-map-port)))

;;;###autoload
(defun manifolding-mind-map-node-zoom (&optional id speed padding)
  "Move the view of the graph to current node.
or optionally a node of your choosing.
Optionally takes three arguments:
The ID of the node you want to travel to.
The SPEED in ms it takes to make the transition.
The PADDING around the nodes in the viewport."
  (interactive)
  (if-let ((node (or id (org-id-get))))
      (websocket-send-text manifolding-mind-map-ws-socket
                           (json-encode `((type . "command")
                                          (data . ((commandName . "zoom")
                                                   (id . ,node)
                                                   (speed . ,speed)
                                                   (padding . ,padding))))))
    (message "No node found.")))


;;;###autoload
(defun manifolding-mind-map-node-local (&optional id speed padding)
  "Open the local graph view of the current node.
Optionally with ID (string), SPEED (number, ms) and PADDING (number, px)."
  (interactive)
  (if-let ((node (or id (org-id-get))))
      (websocket-send-text manifolding-mind-map-ws-socket
                           (json-encode `((type . "command")
                                          (data . ((commandName . "local")
                                                   (id . ,node)
                                                   (speed . ,speed)
                                                   (padding . ,padding))))))
    (message "No node found.")))


(defun manifolding-mind-map-change-local-graph (&optional id manipulation)
  "Add or remove current node to the local graph. If not in local mode, open local-graph for this node."  
  (interactive)
  (if-let ((node (or id (org-id-get))))
      (websocket-send-text manifolding-mind-map-ws-socket
                           (json-encode `((type . "command")
                                          (data . ((commandName . "change-local-graph")
                                                   (id . ,node)
                                                   (manipulation . ,(or manipulation "add")))))))
    (message "No node found.")))

;;;###autoload
(defun manifolding-mind-map-add-to-local-graph (&optional id)
  "Add current node to the local graph. If not in local mode, open local-graph for this node."
  (interactive)
  (manifolding-mind-map-change-local-graph id "add"))

;;;###autoload
(defun manifolding-mind-map-remove-from-local-graph (&optional id)
  "Remove current node from the local graph. If not in local mode, open local-graph for this node."
  (interactive)
  (manifolding-mind-map-change-local-graph id "remove"))

;;;###autoload
(defun manifolding-mind-map-sync-theme ()
  "Sync your current Emacs theme with manifolding-mind-map."
  (interactive)
  (websocket-send-text manifolding-mind-map-ws-socket
                       (json-encode `((type . "theme")
                                      (data . ,(manifolding-mind-map--update-theme))))))

;;; Obsolete commands
(define-obsolete-function-alias #'mmm-open #'manifolding-mind-map-open "0.1")
(define-obsolete-function-alias #'mmm-node-local #'manifolding-mind-map-node-local "0.1")
(define-obsolete-function-alias #'mmm-node-zoom #'manifolding-mind-map-node-zoom "0.1")
(define-obsolete-function-alias #'mmm-sync-theme #'manifolding-mind-map-sync-theme "0.1")

;;;###autoload
(define-minor-mode manifolding-mind-map-follow-mode
  "Set whether ORUI should follow your every move in Emacs."
  :lighter " manifolding-mind-map"
  :global t
  :group 'manifolding-mind-map
  :init-value nil
  (if manifolding-mind-map-follow-mode
      (progn
        (add-hook 'post-command-hook #'manifolding-mind-map--update-current-node)
        (message "manifolding-mind-map will now follow you around."))
    (remove-hook 'post-command-hook #'manifolding-mind-map--update-current-node)
    (message "manifolding-mind-map will now leave you alone.")))

(provide 'manifolding-mind-map)
;;; manifolding-mind-map.el ends here
