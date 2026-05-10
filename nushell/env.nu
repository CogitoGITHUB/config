# /home/aoeu/.config/nushell/env.nu

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


$env.FZF_DEFAULT_OPTS = "--color=fg:#8B0000,fg+:#FFFFFF,bg+:#8B0000,hl:#CC0000,hl+:#FFFFFF,header:#8B0000,spinner:#8B0000,info:#999999,pointer:#8B0000,marker:#8B0000,prompt:#8B0000,border:#8B0000,separator:#8B0000,scrollbar:#8B0000 --border=rounded --padding=1 --margin=1 --info=inline --bind=ctrl-a:select-all --bind=ctrl-j:down --bind=ctrl-k:up"