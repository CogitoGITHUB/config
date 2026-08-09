-- modules/autostart.lua
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("awww img /home/aoeu/.config/wallpaper/roses/rose-on-book.jpg")
    hl.exec_cmd("ghostty")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("omarchy-tui-shell start")
end)