-- modules/autostart.lua
hl.on("hyprland.start", function()
    hl.exec_cmd("wezterm")
    hl.exec_cmd("qutebrowser")
    hl.exec_cmd("hypridle")
end)