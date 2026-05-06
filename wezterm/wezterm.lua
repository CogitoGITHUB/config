local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- ===== Terminal colors - White theme with dark red accents =====
local colors = {
foreground = '#8B0000',
background = '#ffffff',
cursor_bg = '#8B0000',
cursor_fg = '#ffffff',
selection_fg = '#ffffff',
selection_bg = '#8B0000',
ansi = {
"#8B0000", "#A52A2A", "#8B0000", "#A52A2A",
"#8B0000", "#A52A2A", "#8B0000", "#A52A2A"
},
brights = {
"#8B0000", "#A52A2A", "#8B0000", "#A52A2A",
"#8B0000", "#A52A2A", "#8B0000", "#A52A2A"
}
}
config.colors = colors

-- ===== Font and basic terminal settings =====
config.font = wezterm.font('JetBrains Mono')
config.font_size = 12
config.scrollback_lines = 20000
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.window_decorations = "NONE"
config.window_background_opacity = 1.0

-- ===== Modal plugin =====
local modal = wezterm.plugin.require("https://github.com/MLFlexer/modal.wezterm")
modal.apply_to_config(config)
modal.set_default_keys(config)

-- ===== Window frame / tab-bar background =====
config.window_frame = {
active_titlebar_bg = '#ffffff',
inactive_titlebar_bg = '#ffffff',
border_left_width = 0,
border_right_width = 0,
border_bottom_height = 0,
}

-- ===== Tabline configuration =====
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
tabline.setup({
options = {
icons_enabled = true,
tabs_enabled = true,
theme = {
foreground = '#8B0000',
background = '#ffffff',
cursor_bg = '#8B0000',
cursor_fg = '#ffffff',
ansi = {
"#8B0000", "#A52A2A", "#8B0000", "#A52A2A",
"#8B0000", "#A52A2A", "#8B0000", "#A52A2A"
},
brights = {
"#8B0000", "#A52A2A", "#8B0000", "#A52A2A",
"#8B0000", "#A52A2A", "#8B0000", "#A52A2A"
}
},
theme_overrides = {
normal_mode = {
a = { fg = '#ffffff', bg = '#8B0000' },
b = { fg = '#8B0000', bg = '#ffffff' },
c = { fg = '#A52A2A', bg = '#ffffff' },
},
copy_mode = {
a = { fg = '#ffffff', bg = '#8B0000' },
b = { fg = '#8B0000', bg = '#ffffff' },
c = { fg = '#A52A2A', bg = '#ffffff' },
},
search_mode = {
a = { fg = '#ffffff', bg = '#8B0000' },
b = { fg = '#8B0000', bg = '#ffffff' },
c = { fg = '#A52A2A', bg = '#ffffff' },
},
tab = {
active = { fg = '#ffffff', bg = '#8B0000' },
inactive = { fg = '#8B0000', bg = '#ffffff' },
inactive_hover = { fg = '#8B0000', bg = '#ffffff' },
},
},
section_separators = '',
component_separators = '',
tab_separators = '',
},
sections = {
tabline_a = { 'mode' },
tabline_b = { 'workspace' },
tabline_c = { ' ' },
tab_active = { 'index', { 'cwd', padding = { left = 0, right = 1 } } },
tab_inactive = { 'index', { 'process', padding = { left = 0, right = 1 } } },
tabline_x = { 'ram', 'cpu' },
tabline_y = { 'datetime', 'battery' },
tabline_z = { 'domain' },
},
})

tabline.apply_to_config(config)

-- ===== Tab bar colors (solid) =====
config.colors.tab_bar = {
background = '#ffffff',
active_tab = {
bg_color = '#8B0000',
fg_color = '#ffffff',
},
inactive_tab = {
bg_color = '#ffffff',
fg_color = '#8B0000',
},
inactive_tab_hover = {
bg_color = '#ffffff',
fg_color = '#A52A2A',
},
new_tab = {
bg_color = '#ffffff',
fg_color = '#8B0000',
},
new_tab_hover = {
bg_color = '#ffffff',
fg_color = '#A52A2A',
},
}

-- ===== Final overrides =====
config.window_frame.active_titlebar_bg = '#ffffff'
config.window_frame.inactive_titlebar_bg = '#ffffff'
config.use_fancy_tab_bar = false
config.window_decorations = "NONE"
config.window_close_confirmation = "NeverPrompt"

return config
