# =============================================================================
# ManifoldOS — Reshaping
# =============================================================================
# Handles system reconfiguration via `guix system reconfigure`.
# Git commits & pushes AFTER a successful reconfigure only.
#
# Depends on ManifoldOS-Reshaping-History.nu being sourced first.
# Public API used from that script:
#   - print-git-sections [repo, changed, push_results]
#   - print-section [label, subtitle, rows]
#   - fetch-repo-stats-from [repo]
#   - fetch-status-from [repo]
#   - fetch-commits-from [repo, n]
# =============================================================================

source ~/.config/nushell/modules/forms/scripts/ManifoldOS-Reshaping-History.nu


# =============================================================================
# SECTION 1 — FLOW ENGINE
# =============================================================================

def rs-flow [steps: list, current: string, timings: record] {
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING 🌹(ansi reset)"
    print $"(ansi grey)  A staged collapse of system state into new configuration.(ansi reset)"
    print ""

    for step in $steps {
        let name      = $step.name
        let elapsed   = ($timings | get -i $name | default "")
        let is_done   = ($elapsed | is-not-empty)
        let is_active = ($name == $current)
        let symbol    = if $is_done and not $is_active { "🌹" } else if $is_active { "►" } else { "○" }
        let suffix    = if $is_active { "───► running" } else if $is_done { $"✓  ($elapsed)" } else { "" }
        print $"  ($symbol)  ($name)  ($suffix)"
    }

    print ""
}


# =============================================================================
# SECTION 2 — ERROR DISPLAY
# =============================================================================

def render-errors [all_output: string] {
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING 🌹(ansi reset)"
    print $"(ansi grey)  Error encountered during workflow.(ansi reset)"
    print ""

    # --- Extract derivation log path ---
    let drv_log_lines = ($all_output | lines | where { |l| $l =~ "View build log at" })
    let drv_log = if ($drv_log_lines | is-empty) {
        ""
    } else {
        $drv_log_lines | first | str replace -r `.*'([^']+)'.*` "$1" | str trim
    }

    # --- Show BUILD LOG from .drv if available ---
    if ($drv_log | is-not-empty) {
        print-section "BUILD LOG" "derivation build output from failed compilation" []
        try {
            ^/run/setuid-programs/sudo zcat $drv_log | bat --language=log --paging=never
        } catch {
            print ""
            try {
                ^/run/setuid-programs/sudo zcat $drv_log
            } catch {
                print $"(ansi grey)  Unable to read log file: ($drv_log)(ansi reset)"
            }
            print ""
        }
    }

    # --- Show error lines from output ---
    let error_lines = (
        $all_output
        | lines
        | where { |l| $l =~ "error:" }
        | each { |l| { error: $l } }
    )
    if ($error_lines | is-not-empty) {
        print-section "ERRORS" "reconfiguration failed because" $error_lines
    }

    # --- Run REPL evaluation to get scheme trace ---
    print-section "SCHEME EVALUATION" "running guix repl to diagnose configuration" []
    let repl_out = (
        try {
            (^/run/setuid-programs/sudo guix repl /ManifoldOS/system.scm out+err>| str trim)
            | lines
            | where { |l|
                not ($l =~ "^;;;" or $l =~ "^scheme@" or $l =~ "^$")
            }
        } catch {
            ["Failed to run guix repl — check permissions and system state"]
        }
    )
    
    if ($repl_out | is-not-empty) {
        $repl_out | each { |l| print $"  ($l)" }
    }
    
    print ""
}


# =============================================================================
# SECTION 3 — GIT OPERATIONS
# =============================================================================

def capture-last-good [] {
    git -C /ManifoldOS rev-parse HEAD | str trim
}

def git-sync [] {
    git -C /ManifoldOS add --all
    let added    = (git -C /ManifoldOS diff --cached --name-only --diff-filter=A | lines | where { |l| $l | is-not-empty } | each { |f| { status: "added"    file: $f  "+": ""  "-": "" } })
    let deleted  = (git -C /ManifoldOS diff --cached --name-only --diff-filter=D | lines | where { |l| $l | is-not-empty } | each { |f| { status: "deleted"  file: $f  "+": ""  "-": "" } })
    let modified = (git -C /ManifoldOS diff --cached --numstat --diff-filter=M   | lines | where { |l| $l | is-not-empty } | each { |line|
        let p = ($line | split row "\t")
        { status: "modified"  file: ($p | get 2)  "+": ($p | get 0)  "-": ($p | get 1) }
    })
    let changed = ($added | append $deleted | append $modified)
    ManifoldOS-Reshaping-History "update"
    $changed
}

def revert-to-last-good [last_good: string] {
    print-section "REVERT" "last known working commit" [
        { key: "Commit"  value: ($last_good | str substring 0..7) }
    ]
    print ""

    let choice = (
        ["no" "yes — revert local files"]
        | input list --fuzzy "Revert local files to last working commit?"
    )

    if ($choice | str starts-with "yes") {
        git -C /ManifoldOS reset --hard $last_good
        print ""
        print-section "REVERTED" "local files restored to last working state" [
            { key: "Commit"  value: ($last_good | str substring 0..7) }
        ]
        print ""
    }
}


# =============================================================================
# SECTION 4 — SYSTEM OPERATIONS
# =============================================================================

def clear-guile-cache [log: string] {
    try { ^/run/setuid-programs/sudo rm -rf /root/.cache/guile/ccache out+err>> $log } catch { }
    try { rm -rf ~/.cache/guile/ccache out+err>> $log } catch { }
}

def run-reconfigure [manifest: string, log: string] {
    let r = (^/run/setuid-programs/sudo guix system reconfigure $manifest | complete)
    $r.stdout out>> $log
    $r.stderr out>> $log
    $r
}

def run-gc [log: string] {
    try { ^/run/setuid-programs/sudo guix system delete-generations out+err>> $log } catch { }
}


# =============================================================================
# SECTION 5 — SUMMARY
# =============================================================================

def render-summary [results: list, changed: list] {
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING 🌹(ansi reset)"
    print $"(ansi grey)  System reconfiguration complete.(ansi reset)"
    print ""

    # --- Steps ---
    print-section "STEPS" "operations performed during this reshape" (
        $results | each { |r| { step: $r.description } }
    )

    # --- Emacs ---
    let emacs_status = (try { herd status emacs-daemon | str trim } catch { "" })
    let emacs_state  = if ($emacs_status =~ "running") { "🌹 running" } else { "🥀 stopped" }
    print-section "EMACS" "control center status" [{ state: $emacs_state }]

    # --- System info ---
    let kernel      = (^uname -r | str trim)
    let disk_cols   = (^df -h / | lines | last | split row " " | where { |it| $it | is-not-empty })
    let disk        = $"($disk_cols | get 2) / ($disk_cols | get 1)"
    let store       = (du --max-depth 0 /gnu/store | get apparent | first | into string)
    let mem_cols    = (try { ^free -h | lines | where { |l| $l =~ "^Mem:" } | first | split row " " | where { |it| $it | is-not-empty } } catch { [] })
    let ram         = $"($mem_cols | get 2) / ($mem_cols | get 1)"
    let uptime      = (^uptime | str trim | str replace -r `.*up\s+` "" | str replace -r `,\s+\d+ user.*` "" | str trim)
    let cpu         = (try { let l = (^cat /proc/loadavg | split row " "); $"($l | get 0) ($l | get 1) ($l | get 2)" } catch { "unavailable" })
    let temp        = (try { let t = (^cat /sys/class/thermal/thermal_zone0/temp | str trim | into int); $"($t / 1000)°C" } catch { "unavailable" })
    let generations = (try { guix system list-generations | lines | where { |l| $l =~ "^Generation" } | length | into string } catch { "unavailable" })

    print-section "SYSTEM" "hardware and runtime state" [
        { key: "Kernel"      value: $kernel }
        { key: "Disk /"      value: $disk }
        { key: "Store"       value: $store }
        { key: "RAM"         value: $ram }
        { key: "CPU Load"    value: $cpu }
        { key: "Temp"        value: $temp }
        { key: "Uptime"      value: $uptime }
        { key: "Generations" value: $generations }
    ]

    # --- Shepherd services ---
    let skip_patterns = [
        "file-system-" "term-" "console-font-" "root" "transient" "timer"
        "loopback" "urandom-seed" "user-file-systems" "user-processes"
        "virtual-terminal" "pam" "system-log"
    ]

    let herd_lines = (^/run/setuid-programs/sudo herd status | lines)
    mut svc_status = ""
    mut svc_rows   = []

    for line in $herd_lines {
        if ($line =~ "^Started:") {
            $svc_status = "running"
        } else if ($line =~ "^Stopped:") {
            $svc_status = "stopped"
        } else if ($line =~ "^One-shot:") {
            $svc_status = ""
        } else if ($line =~ "^Running timers:") {
            $svc_status = ""
        } else {
            let trimmed = ($line | str trim)
            let is_service = ($trimmed | str starts-with "+") or ($trimmed | str starts-with "-")
            if $is_service and $svc_status != "" {
                let name = ($trimmed | str substring 2..)
                let skip = ($skip_patterns | any { |p| $name | str starts-with $p })
                if (not $skip) and ($name | is-not-empty) {
                    let icon = if $svc_status == "running" { "🌹 running" } else { "🥀 stopped" }
                    $svc_rows = ($svc_rows | append { service: $name  state: $icon })
                }
            }
        }
    }

    print-section "SERVICES" "shepherd daemon states" $svc_rows

    # --- Git sections ---
    print-git-sections "/ManifoldOS" $changed $results
}


# =============================================================================
# SECTION 6 — MAIN
# =============================================================================

def ManifoldOS-Reshaping [] {
    let manifest    = "/ManifoldOS/system.scm"
    let log         = $"/tmp/reshape_(date now | format date '%Y%m%d_%H%M%S').log"
    let origin_dir  = ($env.PWD)
    let last_good   = (capture-last-good)

    let steps = [
        { name: "Cache" }
        { name: "Reconfigure" }
        { name: "Commit" }
        { name: "GC" }
    ]
    mut timings = {}

    cd /ManifoldOS

    # --- Step 1: Clear Guile cache ---
    rs-flow $steps "Cache" $timings
    let t = (date now)
    clear-guile-cache $log
    $timings = ($timings | insert Cache $"(((date now) - $t) / 1sec | math round)s")

    # --- Step 2: Reconfigure ---
    rs-flow $steps "Reconfigure" $timings
    let t = (date now)
    let r = (run-reconfigure $manifest $log)
    $timings = ($timings | insert Reconfigure $"(((date now) - $t) / 1sec | math round)s")

    if $r.exit_code != 0 {
        render-errors ($r.stdout + "\n" + $r.stderr)
        revert-to-last-good $last_good
        return
    }

    # --- Step 3: Git commit & push ---
    rs-flow $steps "Commit" $timings
    let t = (date now)
    let changed = (git-sync)
    $timings = ($timings | insert Commit $"(((date now) - $t) / 1sec | math round)s")

    # --- Step 4: GC ---
    rs-flow $steps "GC" $timings
    let t = (date now)
    run-gc $log
    $timings = ($timings | insert GC $"(((date now) - $t) / 1sec | math round)s")

    cd $origin_dir

    let results = [
        { description: "Guile cache cleared" }
        { description: "System reconfigured" }
        { description: "Working state committed & pushed" }
        { description: "Reality reshaped" }
    ]

    render-summary $results $changed
}


# =============================================================================
# SECTION 7 — KEYBINDING
# =============================================================================

$env.config.keybindings = ($env.config.keybindings | append {
    name: ManifoldOS_Reshaping
    modifier: control
    keycode: char_s
    mode: emacs
    event: {
        send: executehostcommand
        cmd: "ManifoldOS-Reshaping"
    }
})