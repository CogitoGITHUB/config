(define-module (substrate user-space root desktop rose-pine-hyprcursor)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (rose-pine-hyprcursor))

(define-public rose-pine-hyprcursor
  (package
    (name "rose-pine-hyprcursor")
    (version "0.3.2")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/ndom91/rose-pine-hyprcursor")
                    (commit "4b02963d0baf0bee18725cf7c5762b3b3c1392f1")))
              (sha256
               (base32 "1wrydz7208nmsrzyf1llgpsc5dw7cgrxmmh3cgdklps1npq81sx2"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("manifest.hl" #$"share/icons/rose-pine-hyprcursor/manifest.hl")
               ("hyprcursors" "share/icons/rose-pine-hyprcursor/"))))
    (home-page "https://github.com/ndom91/rose-pine-hyprcursor")
    (synopsis "Rose Pine cursor theme in Hyprcursor format")
    (description
     "The BreezeX cursor theme remixed with the Rose Pine palette and
repackaged for use with the Hyprcursor format.  Includes the dark version of
the Rose Pine BreezeX cursor theme.")
    (license license:gpl3)))