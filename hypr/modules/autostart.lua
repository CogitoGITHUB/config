-- modules/autostart.lua
hl.on("hyprland.start", function()
    hl.exec_cmd("dms run")
    hl.exec_cmd("wezterm")
    hl.exec_cmd("hypridle")
end)