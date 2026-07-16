(define-module (substrate user-space root loaders networking)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages networking)
  #:use-module ((gnu packages networking) #:select (iwd))
  #:use-module (gnu packages linux)
  #:use-module ((gnu packages version-control) #:select (git))
  #:use-module (substrate user-space root networking version-control github-cli)
  #:use-module (substrate user-space root networking version-control lazygit)
  #:use-module (substrate user-space root networking version-control gitpane)
  #:use-module (substrate user-space root networking yt-dlp)
  #:use-module (substrate user-space root networking tailscale)
  #:use-module (substrate user-space root networking network-manager)
  #:use-module (substrate user-space root networking gazelle-tui)
  #:use-module (substrate user-space root networking bluetooth)
  #:use-module (substrate user-space root networking bluetuith)
  #:use-module (substrate user-space root networking tools)
  #:use-module (substrate user-space root networking netwatch)
  #:use-module (substrate user-space root networking ttl)
  #:use-module (substrate user-space root networking surge)
  #:use-module (substrate user-space root networking kyanos)
  #:use-module (substrate user-space root networking lazyssh)
  #:use-module (substrate user-space root networking ligolo-ng)
  #:use-module (substrate user-space root networking noodle)
  #:use-module (gnu services)
  #:use-module (gnu services networking)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services base)
  #:use-module (gnu services desktop)
  #:use-module (guix gexp)
  #:re-export (yt-dlp gazelle-tui bluez bluetuith config-tailscaled-service-type
                nmap wireshark bind-dns iperf iproute iwd netwatch ttl gitpane surge kyanos lazyssh ligolo-agent ligolo-proxy noodle)
  #:export (root-networking-packages root-networking-services))

(define-public root-networking-packages
  (list git github-cli lazygit gitpane openssh curl yt-dlp tailscale nss-certs network-manager gazelle-tui bluez bluetuith nmap wireshark bind-dns iperf iproute iwd netwatch ttl surge kyanos lazyssh ligolo-agent ligolo-proxy noodle))

(define-public root-networking-services
  (list (service network-manager-service-type
                 (network-manager-configuration
                  (shepherd-requirement '(iwd))))
        (service iwd-service-type)
        (service bluetooth-service-type
                 (bluetooth-configuration
                  (auto-enable? #t)))
        (service config-tailscaled-service-type)))
