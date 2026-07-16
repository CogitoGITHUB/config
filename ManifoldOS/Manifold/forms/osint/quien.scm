;; quien has an alias whois = quien in nushell's cli.nu
(define-module (forms osint quien)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (quien))

(define-public quien
  (package
    (name "quien")
    (version "0.12.0")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/retlehs/quien/releases/download/v" version
              "/quien_linux_amd64.tar.gz"))
        (sha256 (base32 "10zdiwkdpdgiww42fh2s2i3g25kypxjvwfbrwibywx03c7l45bia"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan '(("quien" "bin/"))))
    (native-inputs (list gzip))
    (home-page "https://github.com/retlehs/quien")
    (synopsis "Better whois and domain intelligence TUI")
    (description
     "Quien is a domain intelligence toolkit with an interactive TUI.
It provides RDAP/whois lookups, DNS, mail configuration audit (MX, SPF,
DMARC, DKIM, BIMI), SSL/TLS, HTTP headers, SEO analysis, tech stack
detection, and Core Web Vitals via the CrUX API.  JSON subcommands
available for scripting.")
    (license license:expat)))
