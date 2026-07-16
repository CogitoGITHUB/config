(define-module (substrate user-space root shell fetch neofetch)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (neofetch))

(define-public neofetch
  (package
    (name "neofetch")
    (version "7.1.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/dylanaraps/neofetch")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
                (base32
                  "0i7wpisipwzk0j62pzaigbiq42y1mn4sbraz4my2jlz6ahwf00kv"))))
    (build-system gnu-build-system)
    (arguments
      (list #:tests? #f
            #:make-flags
            #~(list (string-append "PREFIX=" #$output))
            #:phases
            #~(modify-phases %standard-phases
                (delete 'configure))))
    (home-page "https://github.com/dylanaraps/neofetch")
    (synopsis "System information script")
    (description "Neofetch is a command-line system information tool written in
Bash.  Neofetch displays information about your system next to an image, your OS
logo, or any ASCII file of your choice.  The main purpose of Neofetch is to be
used in screenshots to show other users what operating system or distribution
you are running, what theme or icon set you are using, etc.")
    (license license:expat)))
