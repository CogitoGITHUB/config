# Wallpaper picker keybindings
let keybindings = [
    # Launch wallpaper picker
    {
        name: wallpaper_picker
        modifier: control
        keycode: char_w
        mode: emacs
        event: {
            send: "executehostcommand"
            cmd: "~/.config/hypr/scripts/wallpaper-picker.sh"
        }
    }
];

# Merge wallpaper keybindings with existing keybindings
$env.config.keybindings ++= $keybindings
