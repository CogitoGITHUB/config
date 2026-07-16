(define-module (substrate user-space root security fail2ban)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages dns)
  #:use-module (gnu packages gawk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages mail)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages web)
  #:export (fail2ban))

(define-public fail2ban
  (package
    (name "fail2ban")
    (version "1.1.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/fail2ban/fail2ban")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0lfakna6ad2xwz95sjxzkavipcsxiy7ybavkdkf9zzmspf2ws4yk"))))
    (build-system pyproject-build-system)
    (arguments
     (list #:tests? #f))
    (native-inputs (list python-setuptools python-aiosmtpd))
    (inputs (list gawk
                  coreutils-minimal
                  curl
                  grep
                  jq
                  iproute
                  ipset
                  iptables
                  `(,isc-bind "utils")
                  nftables
                  perl
                  python-pyinotify
                  sed
                  sendmail
                  sqlite
                  whois))
    (home-page "http://www.fail2ban.org")
    (synopsis "Daemon to ban hosts that cause multiple authentication errors")
    (description "Fail2Ban scans log files and bans IP addresses conducting
too many failed login attempts by updating firewall rules.")
    (license license:gpl2+)))
