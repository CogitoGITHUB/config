(define-module (substrate user-space root networking tools)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages networking)
  #:use-module ((gnu packages dns) #:select (isc-bind))
  #:use-module (gnu packages linux)
  #:re-export (nmap wireshark iperf iproute)
  #:export (bind-dns))

(define-public bind-dns isc-bind)
