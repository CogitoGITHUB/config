let keybindings = [
  {
    name: Weather
    modifier: control
    keycode: char_W
    mode: emacs
    event: {
      send: executehostcommand
      cmd: "ManifoldOS-Weather"
    }
  }
  
{
    name: rmpc
    modifier: control
    keycode: char_p
    mode: emacs
    event: {
      send: executehostcommand
      cmd: "rmpc"
    }
  }
  {
    name: htop
    modifier: control
    keycode: char_h
    mode: emacs
    event: {
      send: executehostcommand
      cmd: "htop"
    }
  }
  {
    name: opencode
    modifier: control
    keycode: char_o
    mode: emacs
    event: {
      send: executehostcommand
      cmd: "opencode"
    }
  }
{
    name: zoxide_fzf
    modifier: control
    keycode: char_u
    mode: emacs
    event: {
      send: executehostcommand
      cmd: "let sel = (try { zoxide query --list | to text | fzf } catch { '' }); if ($sel | str trim) != '' { cd ($sel | str trim) }"
    }
  }
];

$env.config.keybindings ++= $keybindings