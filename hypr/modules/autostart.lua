-- modules/autostart.lua
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("awww img /home/aoeu/.config/wallpapers/pics/roses/roses.jpg")
    hl.exec_cmd("wezterm")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("omarchy-tui-shell start")
end)