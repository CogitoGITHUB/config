def zellij-clean [] {
  zellij ls | ansi strip | lines | where { |l| ($l | str contains "current") == false } | each { |l| zellij delete-session --force ($l | split row " " | first | str trim) }
}



def wait-daemon [] {
  while (not ("/run/user/1000/emacs/server" | path exists)) {
    sleep 1sec
  }
}
def emacs [...args] {
  wait-daemon
  ^emacsclient ...$args
}
def e [...args] {
  wait-daemon
  ^emacsclient -nw ...$args
}
def d [...args] {
  wait-daemon
  ^emacsclient -nw . ...$args
}
def t [...args] {
  wait-daemon
  ^emacsclient -nw TODO.org ...$args
}

# needs sudo to work
alias gazelle = sudo gazelle

alias sleep = psleep --style bar

alias cp = cpx

alias whois = quien

