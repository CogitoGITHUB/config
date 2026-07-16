;; Audio packages and services
(define-module (substrate user-space root loaders audio)
  #:use-module (substrate user-space root audio music mpd)
  #:use-module (substrate user-space root audio music rmpc)
  #:use-module (substrate user-space root audio music cava)
  #:use-module (substrate user-space root audio music lyse)
  #:use-module (substrate user-space root audio alsa)
  #:use-module (substrate user-space root audio wireplumber)
  #:use-module (substrate user-space root audio music-production music-production)
  #:use-module (gnu packages music)
  #:export (root-audio-packages root-audio-services))

(define-public root-audio-packages
  (append (list mpd rmpc cava lyse playerctl wireplumber (@ (gnu packages linux) pipewire))
          music-production-packages))

(define-public root-audio-services
  (list mpd-service alsa-service))