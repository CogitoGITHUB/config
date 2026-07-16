(define-module (substrate user-space root networking gazelle-tui)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base)
  #:use-module (substrate user-space root shell archive unzip)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages tree-sitter)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (gazelle-tui))

(define-public gazelle-tui
  (package
    (name "gazelle-tui")
    (version "1.8.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/Zeus-Deus/gazelle-tui/archive/refs/tags/v"
                           version ".tar.gz"))
       (sha256
        (base32 "0h9j38q24sk0x265g7rrd161z377pb7lvk650b3ylzqmvwwrfipx"))))
    (build-system trivial-build-system)
    (arguments
     '(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let* ((out     (assoc-ref %outputs "out"))
                (bin     (string-append out "/bin"))
                (share   (string-append out "/share/gazelle-tui"))
                (source  (assoc-ref %build-inputs "source"))
                (python  (assoc-ref %build-inputs "python"))
                (tar     (assoc-ref %build-inputs "tar"))
                (gzip    (assoc-ref %build-inputs "gzip"))
                (textual (assoc-ref %build-inputs "python-textual"))
                (rich    (assoc-ref %build-inputs "python-rich"))
                (mdit    (assoc-ref %build-inputs "python-markdown-it-py"))
                (plat    (assoc-ref %build-inputs "python-platformdirs"))
                (typing  (assoc-ref %build-inputs "python-typing-extensions"))
                (treesit (assoc-ref %build-inputs "python-tree-sitter"))
                (pyver   "3.11")
                (pylib   (string-append
                          share ":"
                          textual "/lib/python" pyver "/site-packages:"
                          rich "/lib/python" pyver "/site-packages:"
                          mdit "/lib/python" pyver "/site-packages:"
                          plat "/lib/python" pyver "/site-packages:"
                          typing "/lib/python" pyver "/site-packages:"
                          treesit "/lib/python" pyver "/site-packages")))
           (setenv "PATH" (string-append tar "/bin:" gzip "/bin"))
           (mkdir-p "tmp")
           (with-directory-excursion "tmp"
             (invoke "tar" "xvf" source "--strip-components=1"))
           (mkdir-p bin)
           (copy-recursively "tmp" share)
           (with-output-to-file (string-append bin "/gazelle")
             (lambda ()
               (format #t "#!/bin/sh~%export PYTHONPATH=\"~a:${PYTHONPATH:-}\"~%exec ~a/bin/python3 -c \"import sys; sys.path.insert(0, '~a'); from app import Gazelle; Gazelle().run()\" \"$@\"~%"
                       pylib python share)))
           (chmod (string-append bin "/gazelle") #o755)
           #t))))
    (inputs
     (list python
           python-textual
           python-rich
           python-markdown-it-py
           python-platformdirs
           python-typing-extensions
           python-tree-sitter))
    (native-inputs
     (list gzip tar))
    (home-page "https://github.com/Zeus-Deus/gazelle-tui")
    (synopsis "NetworkManager TUI with 802.1X enterprise WiFi support")
    (description
     "Gazelle is a minimal, keyboard-driven terminal user interface for
NetworkManager.  It provides complete 802.1X enterprise WiFi support (PEAP/TTLS/TLS),
VPN management, WWAN/cellular support, hidden SSID networks, and WPA3-OWE.
All connections are stored in NetworkManager and persist across reboots.")
    (license license:expat)))
