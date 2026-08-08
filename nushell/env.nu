$env.PROMPT_INDICATOR_VI_INSERT = $"(ansi white): "
$env.PROMPT_INDICATOR_VI_NORMAL = $"(ansi white)〉"

# /home/aoeu/.config/nushell/env.nu
$env._ZO_DATA_DIR = "/home/aoeu/.config/nushell"
$env.EDITOR = "emacs"
$env.XDG_RUNTIME_DIR = $"/run/user/(id -u | str trim)"

# --- Guix Configuration ---
$env.GUIX_PROFILE = "/root/.config/guix/current"
$env.GUIX_SUBSTITUTE_URLS = "https://ci.guix.gnu.org https://bordeaux.guix.gnu.org"

# --- Guile Init Symlink ---
if not ($"($env.HOME)/.guile" | path exists) {
    ^ln -sf /ManifoldOS/guile-init/init.scm $"($env.HOME)/.guile"
}
if not ("/root/.guile" | path exists) {
    ^/run/setuid-programs/sudo ln -sf /ManifoldOS/guile-init/init.scm /root/.guile
}

# --- PATH Setup ---
let path_without_setuid = ($env.PATH | where {|x| $x != "/run/setuid-programs" })
$env.PATH = [
    "/run/setuid-programs"
    $"($env.GUIX_PROFILE)/bin"
    $"($env.GUIX_PROFILE)/sbin"
    "/home/aoeu/.guix-profile/bin"
    "/run/current-system/profile/sbin"
    ...$path_without_setuid
]

# --- Guix Home Bootstrap ---
if ($"($env.HOME)/.guix-home/on-first-login" | path exists) {
    ^$"($env.HOME)/.guix-home/on-first-login"
}


$env.FZF_DEFAULT_OPTS = "--color=fg:#FFFFFF,fg+:#FFFFFF,hl:#FFFFFF,hl+:#FFFFFF,header:#FFFFFF,spinner:#FFFFFF,info:#FFFFFF,pointer:#FFFFFF,marker:#FFFFFF,prompt:#FFFFFF,border:#FFFFFF,separator:#FFFFFF,scrollbar:#FFFFFF --border=rounded --padding=1 --margin=1 --info=inline --bind=ctrl-a:select-all --bind=ctrl-j:down --bind=ctrl-k:up"


$env.PATH = ($env.PATH | prepend $"($env.HOME)/.nix-profile/bin")
