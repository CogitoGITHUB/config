local mod = "SUPER"

-- ── Applications ───────────────────────────────────────────────────────────
hl.bind(mod .. " + Return",     hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + BackSpace",  hl.dsp.window.close())
hl.bind(mod .. " + E",          hl.dsp.exec_cmd("emacs"))
hl.bind(mod .. " + Q",          hl.dsp.exec_cmd("qutebrowser"))
hl.bind(mod .. " + G",          hl.dsp.exec_cmd("pypr toggle term"))
hl.bind(mod .. " + X",          hl.dsp.exec_cmd("pypr expose"))
hl.bind(mod .. " + S",          hl.dsp.exec_cmd("pypr stash toggle"))
hl.bind(mod .. " + SHIFT + S",  hl.dsp.exec_cmd("pypr toggle_special"))
hl.bind(mod .. " + L",          hl.dsp.exec_cmd("LOCK-SCREEN_MODE=lockd quickshell --path /home/aoeu/.config/lock-screen/greeter.qml"))

-- ── Layout navigation ──────────────────────────────────────────────────────
hl.bind(mod .. " + T",          hl.dsp.layout("cyclenext"))
hl.bind(mod .. " + right",      hl.dsp.layout("cyclenext"))
hl.bind(mod .. " + H",          hl.dsp.layout("cycleprev"))
hl.bind(mod .. " + left",       hl.dsp.layout("cycleprev"))

-- ── Workspaces ─────────────────────────────────────────────────────────────
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,               hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(mod .. " + SHIFT + " .. i,       hl.dsp.window.move({ workspace = tostring(i) }))
end
hl.bind(mod .. " + 0",          hl.dsp.focus({ workspace = "10" }))
hl.bind(mod .. " + SHIFT + 0",  hl.dsp.window.move({ workspace = "10" }))

-- ── Audio ──────────────────────────────────────────────────────────────────
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),   { repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     { locked = true })

-- ── Brightness ─────────────────────────────────────────────────────────────
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { repeating = true })

-- ── Media ──────────────────────────────────────────────────────────────────
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),        { locked = true })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),    { locked = true })

-- ── Gestures ───────────────────────────────────────────────────────────────
hl.gesture(3, "left",  hl.dsp.layout("cycleprev"))
hl.gesture(3, "right", hl.dsp.layout("cyclenext"))
hl.gesture(3, "up",    hl.dsp.focus({ workspace = "e-1" }))
hl.gesture(3, "down",  hl.dsp.focus({ workspace = "e+1" }))