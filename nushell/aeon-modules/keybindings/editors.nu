let keybindings = [ 
{
    name: "emacs"
    modifier: "control"
    keycode: "char_e"
    mode: ["emacs"]
    event: {
      send: "executehostcommand"
      cmd: 'emacs -nw'
    }
  },

  {
    name: "nvim"
    modifier: "control"
    keycode: "char_n"
    mode: ["emacs"]
    event: {
      send: "executehostcommand"
      cmd: 'let file = (try { fzf } | default ""); if $file != "" { nvim $file }'
    }
  },
]

$env.config.keybindings ++= $keybindings

