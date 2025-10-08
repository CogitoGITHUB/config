let keybindings = [
   
    # Clear
    {
      name: superfile_launch
      modifier: control
      keycode: char_v
      mode: emacs
      event: {
        send: executehostcommand
        cmd: "clear"
      }
    },

    # Launch Superfile
    {
      name: superfile_launch
      modifier: control
      keycode: char_s
      mode: emacs
      event: {
        send: executehostcommand
        cmd: "superfile"
      }
    },
     
    # Tmux
    {
      name: tmux
      modifier: control
      keycode: char_t
      mode: emacs
      event: {
        send: executehostcommand
        cmd: "tmux"
      }
    },

    # Launch Hyprland from TTY
    {
      name: hyprland
      modifier: control
      keycode: char_e
      mode: emacs
      event: {
        send: executehostcommand
        cmd: "hyprland"
      }
    },

    # Fastfetch system info
    {
      name: fastfetch
      modifier: control
      keycode: char_f
      mode: emacs
      event: {
        send: executehostcommand
        cmd: "fastfetch"
      }
    },

    # Reboot system
    {
      name: reboot
      modifier: control
      keycode: char_q
      mode: emacs
      event: {
        send: executehostcommand
        cmd: "systemctl reboot"
      }
    }
];

$env.config.keybindings ++= $keybindings
