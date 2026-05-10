config.load_autoconfig(False)

# -------------------------------------------------
# Window / layout
# -------------------------------------------------
c.tabs.show = "never"
c.statusbar.show = "always"
c.window.hide_decoration = True
c.statusbar.padding = {"top": 0, "bottom": 0, "left": 4, "right": 4}
c.statusbar.widgets = ["keypress"]

# -------------------------------------------------
# Colors: pure monochrome
# -------------------------------------------------
white = "#ffffff"
black = "#000000"

c.colors.webpage.preferred_color_scheme = "light"
c.colors.webpage.bg = white
c.colors.webpage.darkmode.enabled = False

# -------------------------------------------------
# Statusbar
# -------------------------------------------------
c.colors.statusbar.normal.bg = white
c.colors.statusbar.normal.fg = black
c.colors.statusbar.insert.bg = white
c.colors.statusbar.insert.fg = black
c.colors.statusbar.command.bg = white
c.colors.statusbar.command.fg = black
c.colors.statusbar.caret.bg = white
c.colors.statusbar.caret.fg = black

# -------------------------------------------------
# Tabs (hidden)
# -------------------------------------------------
c.colors.tabs.bar.bg = white
c.colors.tabs.even.bg = white
c.colors.tabs.odd.bg = white
c.colors.tabs.selected.even.bg = white
c.colors.tabs.selected.odd.bg = white
c.colors.tabs.even.fg = black
c.colors.tabs.odd.fg = black
c.colors.tabs.selected.even.fg = black
c.colors.tabs.selected.odd.fg = black

# -------------------------------------------------
# Completion menu
# -------------------------------------------------
c.colors.completion.fg = black
c.colors.completion.even.bg = white
c.colors.completion.odd.bg = white
c.colors.completion.match.fg = black
c.colors.completion.category.bg = white
c.colors.completion.category.fg = black
c.colors.completion.item.selected.bg = white
c.colors.completion.item.selected.fg = black

# -------------------------------------------------
# Prompts / messages
# -------------------------------------------------
c.colors.prompts.bg = white
c.colors.prompts.fg = black
c.colors.prompts.selected.bg = white
c.colors.messages.info.bg = white
c.colors.messages.info.fg = black
c.colors.messages.error.bg = white
c.colors.messages.error.fg = black

# -------------------------------------------------
# Downloads
# -------------------------------------------------
c.colors.downloads.bar.bg = white
c.colors.downloads.start.bg = white
c.colors.downloads.start.fg = black
c.colors.downloads.error.bg = white
c.colors.downloads.error.fg = black

# -------------------------------------------------
# Hints (pure minimal)
# -------------------------------------------------
c.hints.chars = "aoeu"
c.hints.border = "0px solid " + white
c.hints.radius = 0
c.colors.hints.bg = white
c.colors.hints.fg = black
c.colors.hints.match.fg = black

# -------------------------------------------------
# Caret movement (HTNS Dvorak)
# -------------------------------------------------
config.bind('h', 'move-to-prev-char', mode='caret')  # left
config.bind('t', 'move-to-next-char', mode='caret')  # right
config.bind('n', 'move-to-next-line', mode='caret')  # down
config.bind('s', 'move-to-prev-line', mode='caret')  # up
config.bind('f', 'move-to-next-word', mode='caret')
config.bind('d', 'move-to-prev-word', mode='caret')
config.bind('0', 'move-to-start-of-line', mode='caret')
config.bind('$', 'move-to-end-of-line', mode='caret')

# -------------------------------------------------
# Clipboard
# -------------------------------------------------

c.content.javascript.clipboard = "access"
