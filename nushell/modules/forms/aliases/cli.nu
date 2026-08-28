def zellij-clean [] {
  zellij ls | ansi strip | lines | where { |l| ($l | str contains "current") == false } | each { |l| zellij delete-session --force ($l | split row " " | first | str trim) }
}



def e [...args] {
  ^emacs ...$args
}
def d [...args] {
  ^emacs . ...$args
}
def t [...args] {
  ^emacs TODO.org ...$args
}

# needs sudo to work
alias gazelle = sudo gazelle

alias sleep = psleep --style bar

alias cp = cpx

alias whois = quien

