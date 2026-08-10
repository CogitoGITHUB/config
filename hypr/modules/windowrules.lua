-- modules/windowrules.lua
-- HyprWindowShade: apply the animated reading shader to every window.
hl.window_rule({
    match = { class = ".*" },
    tag = "+shader:/home/aoeu/.config/hypr/shaders/reading_mode.glsl",
})
