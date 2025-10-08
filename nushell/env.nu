zoxide init nushell | save -f ~/.zoxide.nu
# Correct Nushell Syntax for defining FZF_DEFAULT_OPTS:

$env.FZF_DEFAULT_OPTS = (
    '--color=fg:#d0d0d0,fg+:#d0d0d0,bg:#121212,bg+:#262626' +
    ' --color=hl:#ffffff,hl+:#ffffff,info:#ffffff,marker:#ffffff' +
    ' --color=prompt:#ffffff,spinner:#ffffff,pointer:#ffffff,header:#ffffff' +
    ' --color=border:#262626,label:#aeaeae,query:#d9d9d9' +
    ' --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "' +
    ' --marker=">" --pointer="◆" --separator="─" --scrollbar="│"' +
    ' --layout="reverse"'
)
