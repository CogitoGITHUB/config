let keybindings = [
  {
    name: Weather
    modifier: control
    keycode: char_w
    mode: [emacs, vi_insert, vi_normal]
    event: {
      send: executehostcommand
      cmd: "ManifoldOS-Weather"
    }
  }
  {
    name: rmpc
    modifier: control
    keycode: char_p
    mode: [emacs, vi_insert, vi_normal]
    event: {
      send: executehostcommand
      cmd: "rmpc"
    }
  }
  {
    name: herdr
    modifier: control
    keycode: char_h
    mode: [emacs, vi_insert, vi_normal]
    event: {
      send: executehostcommand
      cmd: "herdr"
    }
  }
  {
    name: opencode
    modifier: control
    keycode: char_o
    mode: [emacs, vi_insert, vi_normal]
    event: {
      send: executehostcommand
      cmd: "opencode"
    }
  }
  {
    name: emacs
    modifier: control
    keycode: char_e
    mode: [emacs, vi_insert, vi_normal]
    event: {
      send: executehostcommand
      cmd: "d"
    }
  }
  {
    name: superfile
    modifier: control
    keycode: char_s
    mode: [emacs, vi_insert, vi_normal]
    event: {
      send: executehostcommand
      cmd: "superfile"
    }
  }
  {
    name: dired
    modifier: none
    keycode: char_d
    mode: vi_normal
    event: {
      send: executehostcommand
      cmd: "d"
    }
  }
];

$env.config.keybindings ++= $keybindings