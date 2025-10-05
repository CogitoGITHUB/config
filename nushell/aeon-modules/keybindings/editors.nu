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
]

$env.config.keybindings ++= $keybindings
