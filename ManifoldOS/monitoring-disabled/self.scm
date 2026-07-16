;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024, 2025 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (substrate user-space root monitoring self)
  #:use-module (ice-9 match))

(define-public %oci-channel-url "https://github.com/fishinthecalculator/gocix")

(define-public (oci-module-name? name)
  "Return true if NAME (a list of symbols) denotes a Guix or gocix module."
  (match name
    (('guix _ ...) #t)
    (('gnu _ ...) #t)
    (('oci _ ...) #t)
    (_ #f)))
