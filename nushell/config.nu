# substrate (core layer)
source "~/.config/nushell/modules/substrate/general.nu"
source "~/.config/nushell/modules/substrate/theme.nu"
source "~/.config/nushell/modules/substrate/plugins.nu"
source "~/.config/nushell/modules/substrate/completion.nu"


# forms (interaction layer)
source "~/.config/nushell/modules/forms/keybindings/editors.nu"
source "~/.config/nushell/modules/forms/keybindings/ttycmd.nu"

# --- ManifoldOS Scripts ---
# Load order matters: History must come before Reshaping.
# ManifoldOS-Reshaping.nu depends on reshaping-history-rows
# which is defined in ManifoldOS-Reshaping-History.nu.
# Do NOT reorder these two lines.
source "~/.config/nushell/modules/forms/scripts/ManifoldOS-Reshaping-History.nu"
#source "~/.config/nushell/modules/forms/scripts/ManifoldOS-Reshaping.nu"
source "~/.config/nushell/modules/forms/scripts/ManifoldOS-Build.nu"
source "~/.config/nushell/modules/forms/scripts/ManifoldOS-Weather.nu"

# session / tools
source "~/.config/nushell/zellij.nu"
source "~/.config/nushell/modules/forms/scripts/dir-info.nu"
source "~/.config/nushell/modules/forms/scripts/zoxide.nu"

source ~/.config/nushell/modules/forms/scripts/ManifoldOS-Weather.nu

source "~/.config/nushell/modules/forms/scripts/fzf-tools.nu"


source "~/.config/nushell/modules/forms/aliases/cli.nu"

# external integrations
source ~/.local/share/atuin/init.nu
# source ($nu.data-dir | path join "carapace-init.nu")

#mkdir ($nu.data-dir | path join "vendor/autoload")
#tv init nu | save -f ($nu.data-dir | path join "vendor/autoload/tv.nu")

$env.config.color_config = $light_theme

# starship
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
