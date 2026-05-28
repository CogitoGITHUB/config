-- add suport for quickshell - mode line mode view and add widgets for which key like interface
require("modules.binds.normal_mode")
require("modules.binds.insert_mode")
require("modules.binds.visual_mode")
require("modules.binds.command_mode")
require("modules.binds.waybar_status")

local menu = "rofi -show drun"
local wallpaper_switcher = "~/.config/hypr/scripts/wallpaper-switcher.sh"
local app_switcher = "rofi -show window"

local terminal = "wezterm"
local file_manager = "dolphin"
-- local clipboard_manager = "cliphist list | dmenu | cliphist decode | wl-copy"
local clipboard_manager = "cursor-clip"
local logout_manager = "pidof wlogout || wlogout -p layer-shell -b 4 -L 225 -R 225 -T 375 -B 375"

hl.bind("SUPER + A", hl.dsp.exec_cmd(wallpaper_switcher))
-- hl.bind("SUPER + M", hl.dsp.exec_cmd("espanso"))

hl.bind("SUPER + R", function()
    local active_window = hl.get_active_window()
    if active_window == nil then
        hl.dispatch(hl.dsp.exec_cmd(popup_terminal))
        return
    end

    if active_window.title ~= "popup_terminal" then
        hl.dispatch(hl.dsp.exec_cmd(popup_terminal))
    else
        hl.dispatch(hl.dsp.window.close())
    end
end)

-- Hide or Reload Waybar
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))

-- Laptop multimedia keys for volume and LCD brightness
local volume_up = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
local volume_down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
local audio_mute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
local mic_mute = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(volume_up), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(volume_down), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(audio_mute), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(mic_mute), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })