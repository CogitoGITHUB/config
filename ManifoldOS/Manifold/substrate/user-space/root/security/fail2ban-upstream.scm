(define-module (substrate user-space root security fail2ban-upstream)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system pyproject)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
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
        (base32 "0lfakna6ad2xwz95sjxzkavipcsxiy7ybavkdkf9zzmspf2ws4yk"))
       (modules '((guix build utils)))
       (snippet #~(begin
                    (with-directory-excursion "config"
                      (for-each delete-file
                                '("paths-arch.conf" "paths-debian.conf"
                                  "paths-fedora.conf" "paths-freebsd.conf"
                                  "paths-opensuse.conf" "paths-osx.conf")))))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'create-paths-guix-conf
            (lambda _
              (call-with-output-file "config/paths-guix.conf"
                (lambda (port)
                  (display "[INCLUDES]\n\n" port)
                  (display "before = paths-common.conf\n" port)
                  (display "after = paths-overrides.local\n\n" port)
                  (display "[DEFAULT]\n\n" port)
                  (display "syslog_authpriv = /var/log/secure\n" port)
                  (display "syslog_mail = /var/log/maillog\n" port)
                  (display "syslog_mail_warn = /var/log/maillog\n" port)))))
          (add-after 'unpack 'avoid-external-binary-in-/bin
            (lambda _
              (delete-file "fail2ban/setup.py")
              (substitute* '("bin/fail2ban-testcases" "setup.py")
                ((".*updatePyExec.*") ""))))
          (add-after 'unpack 'patch-setup.py
            (lambda _
              (substitute* "setup.py"
                (("/etc/fail2ban") "etc/fail2ban")
                (("/var/lib/fail2ban") "var/lib/fail2ban")
                (("\"/usr/bin/\"") "\"usr/bin/\"")
                (("\"/usr/lib/fail2ban/\"") "\"usr/lib/fail2ban/\"")
                (("'/usr/share/doc/fail2ban'") "'usr/share/doc/fail2ban'"))))
          (add-after 'unpack 'disable-some-tests
            (lambda _
              (define (make-suite-regex tests)
                (string-append "tests.addTest\\(loadTests\\(("
                               (string-join tests "|")
                               ")\\)\\)"))
              (substitute* "fail2ban/tests/utils.py"
                (((make-suite-regex
                   (list "actiontestcase.CommandActionTest"
                         "misctestcase.SetupTest"
                         "filtertestcase.DNSUtilsNetworkTests"
                         "filtertestcase.IgnoreIPDNS"
                         "filtertestcase.GetFailures"
                         "fail2banclienttestcase.Fail2banServerTest"
                         "servertestcase.ServerConfigReaderTests")))
                 ""))))
          (add-before 'build 'fix-default-config
            (lambda _
              (substitute* '("config/paths-common.conf"
                             "fail2ban/tests/utils.py"
                             "fail2ban/client/configreader.py"
                             "fail2ban/client/fail2bancmdline.py"
                             "fail2ban/client/fail2banregex.py")
                (("/etc/fail2ban")
                 (string-append #$output "/etc/fail2ban"))))))))
    (synopsis "Daemon to ban hosts that cause multiple authentication errors")
    (description "Fail2Ban scans log files and bans IPs with too many failed login attempts.")
    (home-page "http://www.fail2ban.org")
    (license license:gpl2+)))
