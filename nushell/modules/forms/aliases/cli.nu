def zellij-clean [] {
  zellij ls | ansi strip | lines | where { |l| ($l | str contains "current") == false } | each { |l| zellij delete-session --force ($l | split row " " | first | str trim) }
}



def e [...args] {
  ^emacsclient -n -s /run/user/1000/emacs/server ...$args
}
def d [...args] {
  ^emacsclient -n -s /run/user/1000/emacs/server . ...$args
}
def t [...args] {
  ^emacsclient -n -s /run/user/1000/emacs/server TODO.org ...$args
}

# needs sudo to work
alias gazelle = sudo gazelle

alias sleep = psleep --style bar

alias cp = cpx

alias whois = quien

