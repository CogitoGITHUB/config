# ~/.config/nushell/core-modules/plugins.nu

# Top-level plugin configuration
let plugins = {} # Per-plugin configuration

# Plugin garbage collection configuration
let plugin_gc = {
    "default": {
        enabled: true        # automatically stop inactive plugins
        stop_after: 10sec
    }
    plugins: {}
}

# Recommended / useful plugins
let plugins = {
    git: { enabled: true }
    gh: { enabled: true }
    zoxide: { enabled: true }
    starship: { enabled: true }
    carapace: { 
        enabled: true
        config_path: "~/.config/carapace/init.nu"
    }
    atuin: { 
        enabled: true
        config_path: "~/.local/share/atuin/init.nu"
    }
    # Optional extras
    bat: { enabled: true }
    fzf: { enabled: true }
    exa: { enabled: true }
}
