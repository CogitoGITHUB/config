(define-module (substrate user-space root loaders shell)
  #:use-module (substrate user-space root shell nushell)
  #:use-module (substrate user-space root shell television)
  #:use-module (substrate user-space root shell fzf)
  #:use-module (substrate user-space root shell starship)
  #:use-module (substrate user-space root shell bash)
  #:use-module (substrate user-space root shell zoxide)
  #:use-module (substrate user-space root shell carapace)
  #:use-module (substrate user-space root shell atuin)
  #:use-module (substrate user-space root shell superfile)
  #:use-module (substrate user-space root shell system-monitor btop)
  #:use-module (substrate user-space root shell system-monitor htop)
  #:use-module (substrate user-space root shell system-monitor ncdu)
  #:use-module (substrate user-space root shell system-monitor glances)
  #:use-module (substrate user-space root shell system-monitor diskwatch)
  #:use-module (substrate user-space root shell system-monitor syswatch)
  #:use-module (substrate user-space root shell power upower)
  #:use-module (substrate user-space root shell power tlp)
  #:use-module (substrate user-space root shell power acpi)
  #:use-module (substrate user-space root shell archive unzip)
  #:use-module (substrate user-space root shell archive zstd)
  #:use-module (substrate user-space root shell archive xz)
  #:use-module (substrate user-space root shell fetch neofetch)
  #:use-module (substrate user-space root shell fetch fastfetch)
  #:use-module (substrate user-space root shell rip)
  #:use-module (substrate user-space root shell eza)
  #:use-module (substrate user-space root shell herdr)
  #:use-module (substrate user-space root shell zellij)
  #:use-module (substrate user-space root shell psleep)
  #:use-module (substrate user-space root shell twatch)
  #:use-module (substrate user-space root shell broot)
  #:use-module (substrate user-space root shell nur)
  #:use-module (substrate user-space root shell tailspin)
  #:use-module (substrate user-space root shell cpx)
  #:use-module (substrate user-space root shell csakura)
  #:re-export (nushell television fzf starship bash zoxide zellij carapace atuin superfile rip-cli eza herdr psleep twatch broot nur tailspin cpx csakura
htop ncdu glances diskwatch syswatch
               upower tlp acpi
               unzip zstd xz
               neofetch fastfetch)
  #:export (root-shell-packages
            root-shell-system-monitor-packages
            root-shell-power-packages
            root-shell-archive-packages
            root-shell-fetch-packages))

(define root-shell-packages
  (list nushell television fzf starship bash zoxide zellij carapace atuin superfile rip-cli eza herdr psleep twatch broot nur tailspin cpx csakura))

(define-public root-shell-system-monitor-packages
  (list btop htop ncdu glances diskwatch syswatch))

(define-public root-shell-power-packages
  (list upower tlp acpi))

(define-public root-shell-archive-packages
  (list unzip zstd xz))

(define-public root-shell-fetch-packages
  (list neofetch fastfetch))
