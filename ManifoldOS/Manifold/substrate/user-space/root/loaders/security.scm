;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (substrate user-space root loaders security)
  #:use-module (substrate user-space root security age)
  #:use-module (substrate user-space root security gnupg)
  #:use-module (substrate user-space root security fail2ban)
  #:use-module (substrate user-space root security sshguard)
  #:use-module (substrate user-space root security threatdeck)
  #:use-module (substrate user-space root security sliver)
  #:re-export (age
               gnupg
               fail2ban
               sshguard
                threatdeck sliver-client sliver-server)
  #:export (root-security-packages
            root-security-services))

(define-public root-security-packages
  (list age gnupg fail2ban sshguard threatdeck sliver-client sliver-server))

(define-public root-security-services
  '())
