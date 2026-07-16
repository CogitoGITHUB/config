(define-module (substrate user-space root shell archive 7zip)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (gnu packages compression)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (7zip))

(define-public 7zip
  (package
    (name "7zip")
    (version "26.00")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "https://www.7-zip.org/a/7z2600-linux-x64.tar.xz"))
        (sha256
          (base32 "1ipdfz225js41iirv9k298754vx6n8zxa47cbwzy9kcjhjjc8kf7"))))
    (build-system copy-build-system)
    (inputs (list xz))
    (home-page "https://www.7-zip.org/")
    (synopsis "File archiver with high compression ratio")
    (description "7-Zip is a file archiver with a high compression ratio.")
    (license license:lgpl3+)))
