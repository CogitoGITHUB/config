# ~/.config/qutebrowser/config.py
config.load_autoconfig()

# 🖤 Monochrome palette
black = "#000000"
dark_gray = "#1c1c1c"
gray = "#3a3a3a"
light_gray = "#b2b2b2"
white = "#ffffff"

### Statusbar ###
c.colors.statusbar.normal.bg = black
c.colors.statusbar.normal.fg = light_gray
c.colors.statusbar.insert.bg = gray
c.colors.statusbar.insert.fg = white
c.colors.statusbar.command.bg = dark_gray
c.colors.statusbar.command.fg = light_gray
c.colors.statusbar.url.fg = light_gray
c.colors.statusbar.url.hover.fg = white
c.colors.statusbar.url.success.http.fg = light_gray
c.colors.statusbar.url.success.https.fg = white
c.colors.statusbar.url.warn.fg = "#888888"
c.colors.statusbar.url.error.fg = white

### Tabs ###
c.colors.tabs.bar.bg = black
c.colors.tabs.odd.bg = dark_gray
c.colors.tabs.even.bg = dark_gray
c.colors.tabs.odd.fg = light_gray
c.colors.tabs.even.fg = light_gray
c.colors.tabs.selected.odd.bg = gray
c.colors.tabs.selected.odd.fg = white
c.colors.tabs.selected.even.bg = gray
c.colors.tabs.selected.even.fg = white

### Completion Menu ###
c.colors.completion.fg = black
c.colors.completion.fg = light_gray
c.colors.completion.match.fg = white
c.colors.completion.item.selected.bg = gray
c.colors.completion.item.selected.fg = white
c.colors.completion.item.selected.border.top = gray
c.colors.completion.item.selected.border.bottom = gray
c.colors.completion.category.bg = dark_gray
c.colors.completion.category.fg = white
c.colors.completion.scrollbar.bg = dark_gray
c.colors.completion.scrollbar.fg = light_gray

### Downloads ###
c.colors.downloads.bar.bg = black
c.colors.downloads.start.bg = gray
c.colors.downloads.start.fg = white
c.colors.downloads.stop.bg = light_gray
c.colors.downloads.stop.fg = black
c.colors.downloads.error.bg = dark_gray
c.colors.downloads.error.fg = white

### Hints (Link labels) ###
c.colors.hints.bg = light_gray
c.colors.hints.fg = black
c.colors.hints.match.fg = black

### Messages (error/info/warning popups) ###
c.colors.messages.error.bg = black
c.colors.messages.error.fg = white
c.colors.messages.warning.bg = dark_gray
c.colors.messages.warning.fg = white
c.colors.messages.info.bg = black
c.colors.messages.info.fg = light_gray

### Prompts (command prompts) ###
c.colors.prompts.bg = dark_gray
c.colors.prompts.fg = light_gray
c.colors.prompts.selected.bg = gray
c.colors.prompts.selected.fg = white
c.colors.prompts.border = f"1px solid {gray}"

### Web content (optional CSS filter for grayscale websites) ###
c.content.user_stylesheets = ['~/.config/qutebrowser/monochrome.css']


