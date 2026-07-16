(define-module (substrate user-space root shell zoxide)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system cargo)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages rust-apps)
  #:export (zoxide))

(define-public zoxide
  (package
    (name "zoxide")
    (version "0.9.9")
    (source
      (origin
        (method url-fetch)
        (uri (crate-uri "zoxide" version))
        (file-name (string-append name "-" version ".tar.gz"))
        (sha256
          (base32 "11yjqhjqmsmww9cdxwibwm0clzdz6lzrmvnk1w0lyv4vn3jpw62m"))))
    (build-system cargo-build-system)
    (arguments
      (list
        #:install-source? #f
        #:imported-modules (append %copy-build-system-modules
                                   %cargo-build-system-modules)
        #:modules '((guix build cargo-build-system)
                    ((guix build copy-build-system) #:prefix copy:)
                    (guix build utils))
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'patch-references
              (lambda _
                (substitute* (find-files "templates")
                  (("zoxide (add|query)" all)
                   (string-append #$output "/bin/" all))
                  (("(zoxide = \")(zoxide)" _ prefix suffix)
                   (string-append prefix #$output "/bin/" suffix)))))
            (add-after 'install 'install-more
              (lambda args
                (apply (assoc-ref copy:%standard-phases 'install)
                       #:install-plan
                       '(("contrib/completions/zoxide.bash"
                          "share/bash-completion/completions/zoxide")
                         ("contrib/completions/zoxide.elv"
                          "share/elvish/lib/zoxide")
                         ("contrib/completions/zoxide.fish"
                          "share/fish/vendor_completions.d/")
                         ("contrib/completions/zoxide.nu"
                          "share/nushell/vendor/autoload/zoxide")
                         ("contrib/completions/_zoxide"
                          "share/zsh/site-functions/")
                         ("man/man1" "share/man/"))
                       args))))))
    (inputs (cargo-inputs 'zoxide))
    (home-page "https://github.com/ajeetdsouza/zoxide/")
    (synopsis "Fast way to navigate your file system")
    (description
      "Zoxide is a fast replacement for your @command{cd} command.  It keeps
track of the directories you use most frequently, and uses a ranking algorithm
to navigate to the best match.")
    (license license:expat)))
