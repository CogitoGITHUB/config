# substrate (core layer)
source "~/.config/nushell/modules/substrate/general.nu"
source "~/.config/nushell/modules/substrate/theme.nu"
source "~/.config/nushell/modules/substrate/plugins.nu"
source "~/.config/nushell/modules/substrate/completion.nu"


source "~/.config/nushell/modules/forms/keybindings/ttycmd.nu"

# ManifoldOS — load order matters: roots before garden
source "~/.config/nushell/modules/forms/scripts/workspace-vc-roots.nu"
#source "~/.config/nushell/modules/forms/scripts/ManifoldOS-Reshaping.nu"
source "~/.config/nushell/modules/forms/scripts/ManifoldOS-Build.nu"
source "~/.config/nushell/modules/forms/scripts/ManifoldOS-Weather.nu"

# session / tools
source "~/.config/nushell/zellij.nu"
source "~/.config/nushell/modules/forms/scripts/workspace-garden.nu"
source "~/.config/nushell/modules/forms/scripts/zoxide.nu"

source "~/.config/nushell/modules/forms/aliases/cli.nu"

# external integrations
source ~/.local/share/atuin/init.nu

$env.config.color_config = $light_theme

# starship
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")


alias e = if ($env | get -i DISPLAY | is-empty) and ($env | get -i WAYLAND_DISPLAY | is-empty) {
    emacs -nw
} else {
    emacs
}