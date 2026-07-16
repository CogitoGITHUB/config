(define-module (substrate user-space root shell bash)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages readline)
  #:use-module (srfi srfi-26)
  #:export (bash))

(define-public bash
  (let* ((cppflags (string-join '("-DDEFAULT_PATH_VALUE='\"/no-such-path\"'"
                                  "-DSTANDARD_UTILS_PATH='\"/no-such-path\"'"
                                  "-DNON_INTERACTIVE_LOGIN_SHELLS"
                                  "-DSSH_SOURCE_BASHRC"
                                  "-DSYS_BASHRC='\"/etc/bashrc\"'")
                                " "))
         (configure-flags
          ``("--without-bash-malloc"
             "--with-installed-readline"
             ,,(string-append "CPPFLAGS=" cppflags)
             ,(string-append "LDFLAGS=-Wl,-rpath -Wl,"
                             (assoc-ref %build-inputs "readline") "/lib"
                             " -Wl,-rpath -Wl,"
                             (assoc-ref %build-inputs "ncurses") "/lib")))
         (version "5.2"))
    (package
      (name "bash")
      (version version)
      (source (origin
                (method url-fetch)
                (uri (string-append "mirror://gnu/bash/bash-" version ".tar.gz"))
                (sha256
                 (base32 "1yrjmf0mqg2q8pqphjlark0mcmgf88b0acq7bqf4gx3zvxkc2fd1"))))
      (build-system gnu-build-system)
      (outputs '("out" "doc" "include"))
      (inputs (list readline ncurses))
      (arguments
       `(#:configure-flags ,(if (%current-target-system)
                                `(cons* "bash_cv_job_control_missing=no"
                                        ,configure-flags)
                                configure-flags)
         #:parallel-build? #f
         #:parallel-tests? #f
         #:tests? #f
         #:modules ((srfi srfi-26)
                    (guix build utils)
                    (guix build gnu-build-system))
         #:phases
         (modify-phases %standard-phases
           (add-after 'install 'install-sh-symlink
             (lambda* (#:key outputs #:allow-other-keys)
               (let ((out (assoc-ref outputs "out")))
                 (with-directory-excursion (string-append out "/bin")
                   (symlink "bash" "sh")
                   #t))))
           (add-after 'install 'move-development-files
             (lambda* (#:key outputs #:allow-other-keys)
               (let ((out     (assoc-ref outputs "out"))
                     (include (assoc-ref outputs "include"))
                     (lib     (cut string-append <> "/lib/bash")))
                 (mkdir-p (lib include))
                 (rename-file (string-append (lib out) "/Makefile.inc")
                              (string-append (lib include) "/Makefile.inc"))
                 (rename-file (string-append out "/lib/pkgconfig")
                              (string-append include "/lib/pkgconfig"))
                 (substitute* (string-append (lib include) "/Makefile.inc")
                   (("^INSTALL =.*") "INSTALL = install -c\n"))
                 #t))))))
      (native-search-paths
       (list (search-path-specification
              (variable "BASH_LOADABLES_PATH")
              (files '("lib/bash")))))
      (synopsis "The GNU Bourne-Again SHell")
      (description "Bash is the shell, or command-line interpreter, of the GNU system.")
      (license license:gpl3+)
      (home-page "https://www.gnu.org/software/bash/"))))
