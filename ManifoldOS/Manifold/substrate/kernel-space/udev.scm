;;;
;;;; substrate/kernel-space/udev.scm
;;;
;;;; This module defines udev rules and services for device management.
;;;; Re-exports udev-service-type and udev-configuration from (gnu services base)
;;;; for use in service modifications.
;;;
(define-module (substrate kernel-space udev)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu system shadow)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (srfi srfi-1)
  #:re-export (udev-service-type udev-configuration)
  #:export (udev-rules uinput-udev-rule uinput-group-service))

;;;;; udev rules for uinput access
(define-public uinput-udev-rule
  (udev-rule
   "90-uinput.rules"
   (string-append "KERNEL==\"uinput\", GROUP=\"uinput\", MODE=\"0660\"\n")))

;; Add uinput and keyd groups
(define uinput-group-service
  (simple-service 'uinput-group account-service-type
                  (list (user-group (name "uinput"))
                        (user-group (name "keyd")))))

(define-public udev-rules
  (list uinput-udev-rule))
