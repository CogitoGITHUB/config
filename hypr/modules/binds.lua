-- TODO: special/scratchpad workspaces (special:term, special:scratch, special:special) -- figure out later
local mod = "SUPER"
-- ── Applications ───────────────────────────────────────────────────────────
hl.bind(mod .. " + Return",     hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + BackSpace",  hl.dsp.window.close())
hl.bind(mod .. " + E",          hl.dsp.exec_cmd("emacs"))
hl.bind(mod .. " + O",          hl.dsp.exec_cmd("qutebrowser"))
hl.bind(mod .. " + C",          hl.dsp.exec_cmd("google-chrome"))
hl.bind(mod .. " + D",          hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mod .. " + S",          hl.dsp.exec_cmd("omarchy-tui-shell toggle"))
-- ── Fullscreen ─────────────────────────────────────────────────────────────
hl.bind(mod .. " + Space",      hl.dsp.window.fullscreen())
-- ── Layout navigation ──────────────────────────────────────────────────────
hl.bind(mod .. " + right",      hl.dsp.layout("move +col"))
hl.bind(mod .. " + T",          hl.dsp.layout("move +col"))
hl.bind(mod .. " + left",       hl.dsp.layout("move -col"))
hl.bind(mod .. " + H",          hl.dsp.layout("move -col"))
hl.bind(mod .. " + up",   hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + down", hl.dsp.focus({ workspace = "e-1" }))
-- ── Window swap ────────────────────────────────────────────────────────────
hl.bind(mod .. " + SHIFT + right", hl.dsp.layout("swapcol r"))
hl.bind(mod .. " + SHIFT + left",  hl.dsp.layout("swapcol l"))
-- ── Column width (step through explicit_column_widths) ────────────────────
hl.bind(mod .. " + period",          hl.dsp.layout("colresize +conf"),    { repeating = true })
hl.bind(mod .. " + comma",           hl.dsp.layout("colresize -conf"),    { repeating = true })
-- ── Column width (fine, continuous) ───────────────────────────────────────
hl.bind(mod .. " + SHIFT + period",  hl.dsp.layout("colresize +0.05"),   { repeating = true })
hl.bind(mod .. " + SHIFT + comma",   hl.dsp.layout("colresize -0.05"),   { repeating = true })
-- ── Workspaces ─────────────────────────────────────────────────────────────
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(mod .. " + CTRL + " .. i,  hl.dsp.window.move({ workspace = tostring(i) }))
end
hl.bind(mod .. " + 0",          hl.dsp.focus({ workspace = "10" }))
hl.bind(mod .. " + CTRL + 0",   hl.dsp.window.move({ workspace = "10" }))
-- TODO: special/scratchpad workspaces -- figure out later
-- ── DMS Shell ────────────────────────────────────────────────────────────────
hl.bind(mod .. " + V",          hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
hl.bind(mod .. " + M",          hl.dsp.exec_cmd("dms ipc call processlist toggle"))
hl.bind(mod .. " + N",          hl.dsp.exec_cmd("dms ipc call notifications toggle"))
hl.bind(mod .. " + P",          hl.dsp.exec_cmd("dms ipc call notepad toggle"))
hl.bind(mod .. " + X",          hl.dsp.exec_cmd("dms ipc call powermenu toggle"))
hl.bind(mod .. " + SHIFT + L",  hl.dsp.exec_cmd("dms ipc call lock lock"))
hl.bind(mod .. " + SHIFT + Space", hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
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
hl.bind(mod .. " + SHIFT + up",   hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.focus({ workspace = "e-1" }))