let keybindings = [
  {
    name: "nvim"
    modifier: "control"
    keycode: "char_n"
    mode: ["emacs"]
    event: {
      send: "executehostcommand"
      cmd: "nvim ."
    }
  },
  {
    name: "emacs"
    modifier: "control"
    keycode: "char_e"
    mode: ["emacs"]
    event: {
      send: "executehostcommand"
      cmd: "emacs -nw"
    }
  }
]

$env.config.keybindings ++= $keybindings
