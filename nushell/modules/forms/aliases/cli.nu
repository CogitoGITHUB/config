def zellij-clean [] {
  zellij ls | ansi strip | lines | where { |l| ($l | str contains "current") == false } | each { |l| zellij delete-session --force ($l | split row " " | first | str trim) }
}



alias e = emacs -nw
alias d = emacs -nw .
alias t = emacs -nw TODO.org

# needs sudo to work
alias gazelle = sudo gazelle

alias sleep = psleep --style bar

alias cp = cpx

alias whois = quien

