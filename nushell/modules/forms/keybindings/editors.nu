let keybindings = [ 
{
    name: "emacs"
    modifier: "control"
    keycode: "char_e"
    mode: ["emacs"]
    event: {
      send: "executehostcommand"
      cmd: 'emacs -nw --eval "(dired \".\")"'
    }
  },
]

$env.config.keybindings ++= $keybindings

