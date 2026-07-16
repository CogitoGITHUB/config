(define-module (substrate user-space root monitoring grafana-tui)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (grafana-tui))

(define-public grafana-tui
  (package
    (name "grafana-tui")
    (version "0.2.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/lovromazgon/grafana-tui/releases/download/v" version "/grafana-tui_" version "_Linux_x86_64.tar.gz"))
              (sha256
               (base32
                "0940hf34vfainipbxx6cs3nknzxvqqh1wqli577dwaz1120q1w11"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("grafana-tui" "bin/"))))
    (synopsis "Browse Grafana dashboards in the terminal")
    (description "grafana-tui lets you connect to a remote Grafana instance and explore dashboards, panels, and time series data without leaving the command line.")
    (home-page "https://github.com/lovromazgon/grafana-tui")
    (license license:expat)))
