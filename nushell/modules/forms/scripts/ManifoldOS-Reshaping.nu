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

def extract-core-error [all_output: string] {
    let error_lines = (
        $all_output
        | lines
        | where { |l| $l =~ "error:" }
    )
    
    if ($error_lines | is-empty) {
        "Unknown error — check log for details"
    } else {
        $error_lines | first | str trim
    }
}

def render-errors [all_output: string, log_file: string] {
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING 🌹(ansi reset)"
    print $"(ansi grey)  Error encountered during workflow.(ansi reset)"
    print ""

    # --- Extract and show core error ---
    let core_error = (extract-core-error $all_output)
    print-section "❌ ERROR" "reconfiguration failed" [
        { error: $core_error }
    ]
    print ""

    # --- Show log file path ---
    print-section "📋 LOG FILE" "full output saved at" [
        { path: $log_file }
    ]
    print ""

    # --- Ask if user wants to revert to last push ---
    print $"(ansi yellow)🔄 REVERT TO LAST PUSH(ansi reset)"
    print $"(ansi grey)  Go back to last known good commit?(ansi reset)"
    print ""
    let revert_choice = (
        ["no — keep trying to fix" "yes — revert to last push"]
        | input list --fuzzy "Revert working directory?"
    )
    print ""

    let should_revert = ($revert_choice | str starts-with "yes")
    
    if $should_revert {
        return $should_revert
    }

    # --- If not reverting, ask if they want to see full log or diagnostics ---
    print $"(ansi yellow)📖 VIEW OPTIONS(ansi reset)"
    print $"(ansi grey)  How would you like to review the error?(ansi reset)"
    print ""
    let view_choice = (
        ["diagnostics — show error + repl output" "full-log — open log file in pager"]
        | input list --fuzzy "View:"
    )
    print ""

    if ($view_choice | str starts-with "full-log") {
        # Open log in less
        try {
            less $log_file
        } catch {
            print $"(ansi grey)Unable to open log with less, showing raw content:(ansi reset)"
            print ""
            try {
                open --raw $log_file | print
            } catch {
                print $"(ansi red)Failed to read log file(ansi reset)"
            }
        }
    } else {
        # Show diagnostic info: error + warnings
        print-section "⚠ WARNINGS" "non-fatal issues in build log" (
            ($all_output
            | lines
            | where { |l| 
                ($l =~ "warning:" or $l =~ "deprecated:") 
                and (not ($l =~ "ExternalCommand"))
                and (not ($l =~ "Span {"))
            }
            | each { |w| { warning: $w } })
        )
        print ""

        # Show the raw output for inspection
        print-section "📄 RAW OUTPUT" "full error output from guix system reconfigure" []
        print ""
        $all_output | lines | each { |l| print $"  ($l)" }
        print ""
    }

    $should_revert
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
    let returned = (ManifoldOS-Reshaping-History "update")
    $changed
}

def revert-to-last-push [last_good: string] {
    print-section "⏮ REVERTING" "resetting to last pushed commit" [
        { commit: ($last_good | str substring 0..7) }
    ]
    print ""
    
    git -C /ManifoldOS reset --hard $last_good
    
    print-section "✓ REVERTED" "working directory reset to last push" [
        { commit: ($last_good | str substring 0..7) }
    ]
    print ""
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

def render-summary [results: list, changed: list, timings: record, log_file: string] {
    print -n "\e[2J\e[H"
    print ""
    
    # --- Read log for warnings ---
    let log_content = (try { open --raw $log_file } catch { "" })
    let warnings = (extract-warnings $log_content)
    
    # --- Success banner ---
    print $"(ansi green_bold)✓ RECONFIGURATION SUCCESSFUL(ansi reset)"
    print ""
    
    # --- Warnings block (if any) ---
    if ($warnings | is-not-empty) {
        print-section "⚠ WARNINGS" "issues detected in build log" (
            $warnings | each { |w| { warning: $w } }
        )
    } else {
        print ""
    }
    
    # --- Summary metrics ---
    let gen_info = (extract-generation-info "/ManifoldOS")
    let total_time = (
        ($timings | values)
        | each { |v| 
            $v | str replace -r 's$' '' | into float 
        }
        | math sum
    )
    let file_count = ($changed | length)
    let disk_cols = (^df -h / | lines | last | split row " " | where { |it| $it | is-not-empty })
    let disk_usage = ($disk_cols | get 4)
    
    print-section "SUMMARY" "reconfiguration metrics" [
        { metric: "Generation"     value: $gen_info.generation }
        { metric: "Files changed"  value: $file_count }
        { metric: "Total time"     value: $"($total_time | math round --precision 1)s" }
        { metric: "Disk usage /"   value: $disk_usage }
    ]
    print ""

    # --- Steps ---
    print-section "STEPS" "operations performed during this reshape" (
        $results | each { |r| { step: $r.description } }
    )

    # --- Build Timing ---
    print-section "BUILD TIMING" "duration of each step" (
        $timings | transpose key value | each { |e| 
            { step: $e.key  duration: $e.value }
        }
    )

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

    # --- Emacs ---
    let emacs_status = (try { herd status emacs-daemon | str trim } catch { "" })
    let emacs_state  = if ($emacs_status =~ "running") { "🌹 running" } else { "🥀 stopped" }
    print-section "EMACS" "control center status" [{ state: $emacs_state }]
    
    print ""
    print $"(ansi green_bold)✓ System reconfiguration and git history updated(ansi reset)"
    print ""
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
        let should_revert = (render-errors ($r.stdout + "\n" + $r.stderr) $log)
        
        if $should_revert {
            revert-to-last-push $last_good
        }
        
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

    render-summary $results $changed $timings $log
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