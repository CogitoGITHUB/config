def zellij-clean [] {
  zellij ls | ansi strip | lines | where { |l| ($l | str contains "current") == false } | each { |l| zellij delete-session --force ($l | split row " " | first | str trim) }
}



alias emacs = emacsclient
alias e = emacsclient -nw
alias d = emacsclient -nw .
alias t = emacsclient -nw TODO.org

# needs sudo to work
alias gazelle = sudo gazelle

alias sleep = psleep --style bar

alias cp = cpx

alias whois = quien

