-- modules/autostart.lua
hl.on("hyprland.start", function()
    hl.exec_cmd("dms run")
    hl.exec_cmd("wezterm")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("omarchy-tui-shell start")
end)