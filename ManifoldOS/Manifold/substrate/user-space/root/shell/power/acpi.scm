(define-module (substrate user-space root shell power acpi)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (acpi))

(define-public acpi
  (package
    (name "acpi")
    (version "1.7")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "mirror://sourceforge/acpiclient/acpiclient/" version "/" name "-" version ".tar.gz"))
        (sha256
          (base32 "01ahldvf0gc29dmbd5zi4rrnrw2i1ajnf30sx2vyaski3jv099fp"))))
    (build-system gnu-build-system)
    (home-page "https://sourceforge.net/projects/acpiclient/")
    (synopsis "Display information on ACPI devices")
    (description "ACPI command line utility for displaying information about ACPI devices.")
    (license license:gpl2+)))
