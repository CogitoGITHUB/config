# /home/asdf/.config/nushell/env.nu

# --- FZF CONFIGURATION (Your single source of truth) ---

# Clear conflicting FZF variables
$env.FZF_DEFAULT_OPTS_FILE = null
$env.FZF_DEFAULT_OPTS = null

# Set FZF options (Full-screen, No Color, etc.)
$env.FZF_DEFAULT_OPTS = (
    ' --layout=reverse' +
    ' --border="rounded"' +
    ' --prompt="> "' +
    ' --marker=">"' +
    ' --pointer="◆"' +
    ' --height=100%' + 
    ' --margin=0' + 
    ' --color=fg:-1,fg+:-1,bg:-1,bg+:-1' +
    ' --color=hl:-1,hl+:-1,info:-1,marker:-1' +
    ' --color=prompt:-1,spinner:-1,pointer:-1,header:-1' +
    ' --color=border:-1,label:-1,query:-1' +
    ' --preview="cat {}"' +
    ' --preview-window="border-rounded,right:60%"'
)

# --- ZOZIDE FIX (The Clean Solution) ---

# CRITICAL: Force zoxide's internal FZF call to use your global options.
$env._ZO_FZF_OPTS = $env.FZF_DEFAULT_OPTS

# Initialize zoxide (Must be AFTER _ZO_FZF_OPTS is set)
zoxide init nushell | save -f ~/.zoxide.nu
