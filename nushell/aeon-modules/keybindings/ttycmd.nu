let keybindings = [
    # Clear terminal
    {
      name: clear
      modifier: control
      keycode: char_c
      mode: emacs
      event: {
        send: executehostcommand
        cmd: "clear"
      }
    },

    # Launch Hyprland from TTY
    {
      name: hyprland
      modifier: control
      keycode: char_h
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
      keycode: char_r
      mode: emacs
      event: {
        send: executehostcommand
        cmd: "systemctl reboot"
      }
    }
  ];
$env.config.keybindings ++= $keybindings
