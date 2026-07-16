;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (substrate user-space root loaders compute)
  #:use-module (substrate user-space root compute virtualization qemu)
  #:use-module (substrate user-space root compute virtualization libvirt)
  #:use-module (substrate user-space root compute virtualization virt-manager)
  #:use-module (substrate user-space root compute virtualization virt-viewer)
  #:use-module (substrate user-space root compute virtualization spice)
  #:use-module (substrate user-space root compute orchestration ganeti)
  #:use-module (substrate user-space root compute orchestration ganeti-instance-guix)
  #:re-export (qemu libvirt virt-manager virt-viewer spice spice-gtk spice-vdagent ganeti ganeti-instance-guix)
  #:export (root-compute-packages))

(define-public root-compute-packages
  (list qemu libvirt virt-manager virt-viewer spice spice-gtk spice-vdagent ganeti ganeti-instance-guix))
