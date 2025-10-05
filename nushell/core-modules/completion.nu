# Carapace completer
let carapace_completer = {|spans|
    carapace $spans.0 nushell ...$spans | from json
}

# External settings table
let external_settings = {
    enable: true
    max_results: 100
    completer: $carapace_completer
}

# Completion settings
let completions = {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "prefix"
    sort: "smart"
    external: $external_settings
    use_ls_colors: false
}
