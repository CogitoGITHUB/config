;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (core-system user-space root security sops services)
  #:use-module (sops services sops)
  #:re-export (sops-secrets-service-type
               sops-service-configuration))
