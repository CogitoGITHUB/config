# Config — Agent Reference

When the user asks to add, modify, or reconfigure something:

## Emacs modules

**Reference:** `~/.emacs.d/modules/AGENTS.md`
**Location:** `~/.emacs.d/modules/<name>.org`
**Daemon control:** `herd restart emacs-daemon`
**Test:** `emacs --batch --load ~/.emacs.d/init.el --eval '(message "ok")'`

Each module is an `.org` file. `:STRAIGHT:` must be a single line.
Use `:init:` tag for pre-require vars, `:config:` tag (or no tag) for main config.

## ManifoldOS system packages

**Reference:** `~/.config/ManifoldOS/Manifold/Agents.org`
**Config:** `~/.config/ManifoldOS/system.scm`
**Substrate:** `~/.config/ManifoldOS/Manifold/substrate/`
**Packages dir:** `substrate/user-space/root/<category>/`
**Loaders dir:** `substrate/user-space/root/loaders/<category>.scm`
**Reconfigure:** `guix system reconfigure ~/.config/ManifoldOS/system.scm`

## opencode config

**Config:** `~/.config/opencode/opencode.jsonc`
**Themes:** `~/.config/opencode/themes/`
**TUI:** `~/.config/opencode/tui.json`
**Skills:** `~/.config/opencode/skills/<name>/SKILL.md`
**Restart:** always restart opencode after changes
