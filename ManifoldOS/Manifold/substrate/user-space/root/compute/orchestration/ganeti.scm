(define-module (substrate user-space root compute orchestration ganeti)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module ((gnu packages virtualization) #:select (ganeti) #:prefix upstream:)
  #:export (ganeti))

(define ganeti
  (package
    (inherit upstream:ganeti)
    (arguments
      (substitute-keyword-arguments (package-arguments upstream:ganeti)
        ((#:phases phases)
         #~(modify-phases #$phases
             (add-after 'configure 'fix-ghc-package-path
               (lambda _
                 (let* ((ghc-pkg-path (getenv "GHC_PACKAGE_PATH"))
                        (dbs (string-split ghc-pkg-path #\:))
                        (db-flags (string-join
                                    (map (lambda (db)
                                           (string-append "--package-db=" db))
                                         dbs)
                                    " ")))
                   (substitute* "Makefile"
                     (("\\$\\(CABAL_SETUP\\) configure")
                      (string-append
                        "env -u GHC_PACKAGE_PATH $(CABAL_SETUP) configure "
                        db-flags " ")))
                   (unsetenv "GHC_PACKAGE_PATH"))))))))))
