-- TODO: replace pypr scratchpad binds with native special workspaces once pyprland is set up
-- mod + G  → toggle terminal scratchpad
-- mod + X  → expose all windows
-- mod + S  → stash toggle
-- mod + SHIFT + S → toggle special workspace

local mod = "SUPER"

-- ── Applications ───────────────────────────────────────────────────────────
hl.bind(mod .. " + Return",     hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + BackSpace",  hl.dsp.window.close())
hl.bind(mod .. " + E",          hl.dsp.exec_cmd("emacs"))
hl.bind(mod .. " + O",          hl.dsp.exec_cmd("qutebrowser"))
hl.bind(mod .. " + G",          hl.dsp.exec_cmd("pypr toggle term"))
hl.bind(mod .. " + X",          hl.dsp.exec_cmd("pypr expose"))
hl.bind(mod .. " + S",          hl.dsp.exec_cmd("pypr stash toggle"))
hl.bind(mod .. " + SHIFT + S",  hl.dsp.exec_cmd("pypr toggle_special"))

-- ── Layout navigation ──────────────────────────────────────────────────────
hl.bind(mod .. " + right",         hl.dsp.layout("move +col"))
hl.bind(mod .. " + T",             hl.dsp.layout("move +col"))
hl.bind(mod .. " + left",          hl.dsp.layout("move -col"))
hl.bind(mod .. " + H",             hl.dsp.layout("move -col"))
hl.bind(mod .. " + up",            hl.dsp.layout("cycleprev"))
hl.bind(mod .. " + down",          hl.dsp.layout("cyclenext"))

-- ── Window movement ────────────────────────────────────────────────────────
hl.bind(mod .. " + SHIFT + right", hl.dsp.layout("movewindowto r"))
hl.bind(mod .. " + SHIFT + left",  hl.dsp.layout("movewindowto l"))
hl.bind(mod .. " + SHIFT + up",    hl.dsp.layout("movewindowto u"))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.layout("movewindowto d"))

-- ── Column resize ──────────────────────────────────────────────────────────
hl.bind(mod .. " + period",        hl.dsp.layout("colresize +conf"))
hl.bind(mod .. " + comma",         hl.dsp.layout("colresize -conf"))

-- ── Workspaces ─────────────────────────────────────────────────────────────
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,               hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(mod .. " + SHIFT + " .. i,       hl.dsp.window.move({ workspace = tostring(i) }))
end
hl.bind(mod .. " + 0",          hl.dsp.focus({ workspace = "10" }))
hl.bind(mod .. " + SHIFT + 0",  hl.dsp.window.move({ workspace = "10" }))

-- ── Audio ──────────────────────────────────────────────────────────────────
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),  { repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),       { repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),      { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),    { locked = true })

-- ── Brightness ─────────────────────────────────────────────────────────────
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { repeating = true })

-- ── Media ──────────────────────────────────────────────────────────────────
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),        { locked = true })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),    { locked = true })

-- ── Gestures ───────────────────────────────────────────────────────────────
hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })
hl.gesture({ fingers = 3, direction = "vertical",   action = "scroll_move" })
hl.bind(mod .. " + SHIFT + right", function() hl.dispatch(hl.dsp.layout("cyclenext")) end)
hl.bind(mod .. " + SHIFT + left",  function() hl.dispatch(hl.dsp.layout("cycleprev")) end)