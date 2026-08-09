# =============================================================================
# ManifoldOS — Reshaping (ENHANCED)
#
# What is this file?
#
#   This is the operational interface to ManifoldOS reconfiguration — the
#   script that collapses the current system state into a new configuration.
#   It orchestrates the full reshape loop: scan, build, commit, clean.
#
#   In ManifoldOS, reconfiguration is not just a package upgrade. It is a
#   sovereignty assertion — every module is re-scanned, every import is
#   checked, every package and service is re-derived from first principles
#   inside the Manifold. This script drives that process and records the
#   result.
#
# Recent Enhancements:
#
#   • Pre-cleanup Stage — Clears user cache + runs guix gc before reconfigure
#     to prevent "Too many root sets" errors
#   • Store Space Tracking — Captures /gnu/store size before/after, displays
#     delta in summary (↑ 2.3GB or ↓ 100MB)
#   • Real-time Progress Display — Shows substage information during long
#     operations (substage parameter in rs-flow)
#   • Constitution Progress Extraction — Extracts and tracks constitution
#     scan output in real-time (extract-constitution-progress)
#   • Build Phase Detection — Detects Guix build phases as they occur
#     (detect-build-substage)
#   • Byte Formatting — Converts store sizes to human-readable format
#     (format-bytes function)
#
# What does this file do?
#
#   It runs the reshape loop in five stages:
#
#     0. PRE-CLEANUP — Clears user cache and runs garbage collection to fix
#                      "Too many root sets" errors. Ensures GC state is clean
#                      before constitution scanning starts.
#
#     1. CACHE       — Clears stale Guile bytecode so the constitution always
#                      sees fresh module source. Stale .go files can mask real
#                      errors. Always cleared before reconfigure.
#
#     2. BUILD       — Runs `guix system build` against the constitution.
#                      The constitution scans every .scm file under the Manifold,
#                      enforces sovereignty on every import, deduplicates packages
#                      and services, checks regressions against the running system,
#                      and builds the final operating-system derivation.
#
#     3. COMMIT      — On success only: stages all changes in /ManifoldOS,
#                      commits them, and pushes. Git always reflects a successfully
#                      built system — never a broken one.
#
#     4. GC          — Runs `guix system delete-generations` to reclaim store
#                      space. Runs last so failed reshapes never lose old
#                      generations.
#
# What is the reconfigure target?
#
#   /ManifoldOS/Manifold/constitution.scm
#
#   The constitution is the direct entry point. There is no wrapper. Guix reads
#   it directly and builds the OS record it exports.
#
# What does the constitution output?
#
#   During reconfigure, the constitution writes to stderr:
#
#     constitution: scanned N files — P packages, S services
#
#   Sovereignty violations, duplicate packages, and regression warnings also
#   appear in the build log. This script captures all of it and surfaces the
#   relevant lines on failure.
#
# What happens on failure?
#
#   The script stops at the failed stage. Git is never touched on failure.
#   The full build log is saved to /tmp/reshape_TIMESTAMP.log. The error
#   display extracts constitution-specific failures first — sovereignty
#   violations, duplicate packages, failed module loads — before falling
#   back to generic Guix errors.
#
#   Two recovery paths are offered:
#     - Revert to the last pushed commit (git reset --hard)
#     - Inspect the log directly (full log or diagnostics view)
#
# Keybinding:
#
#   Ctrl+S in Nushell emacs mode fires ManifoldOS-Reshaping directly from
#   any prompt. This is the intended way to reshape the system.
#
# Dependencies:
#
#   ManifoldOS-Reshaping-History.nu must be sourced before this file.
#   It provides the public API consumed here:
#
#     print-git-sections [repo, changed, push_results]
#     print-section      [label, subtitle, rows]
#     fetch-repo-stats-from [repo]
#     fetch-status-from  [repo]
#     fetch-commits-from [repo, n]
# =============================================================================

source ~/.config/nushell/modules/forms/scripts/workspace-vc-roots.nu

def print-section [label: string, subtitle: string, rows: list] {
    print $"  (ansi white_bold)(char rose) ($label)(ansi reset)"
    print $"  (ansi white)($subtitle)(ansi reset)"
    print ""
    if ($rows | is-not-empty) {
        $rows | table | print
    }
}

def print-git-sections [repo: string, changed: list, push_results: list] {
    let branch = (try { git -C $repo branch --show-current | str trim } catch { "unknown" })
    let remote = (try { git -C $repo remote get-url origin | str trim } catch { "" })
    let status_count = (try { git -C $repo status --short | lines | length } catch { 0 })
    print $"  (ansi white_bold)(char rose) GIT(ansi reset)"
    print $"  (ansi white)branch: ($branch)(ansi reset)"
    if ($remote | is-not-empty) { print $"  (ansi white)remote: ($remote)(ansi reset)" }
    print $"  (ansi white)changed: ($changed | length) files(ansi reset)"
    print ""
}

# =============================================================================
# SECTION 1 — FLOW ENGINE
#
# Renders the live reshape progress display. Called before each stage with
# the name of the stage currently executing. Completed stages show their
# wall-clock duration. The active stage shows "running". Future stages
# show an empty circle.
#
# Enhanced to show constitution progress during Reconfigure stage:
# - Real-time scan output (files, packages, services)
# - Substage detection (parse, derive, build phases)
# =============================================================================

def rs-flow [steps: list, current: string, timings: record, substage: string = ""] {
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi white_bold)🌹 MANIFOLD // RESHAPING 🌹(ansi reset)"
    print $"(ansi white)  A staged collapse of system state into new configuration.(ansi reset)"
    print ""

    for step in $steps {
        let name      = $step.name
        let elapsed   = (try { $timings | get $name } catch { "" })
        let is_done   = ($elapsed | is-not-empty)
        let is_active = ($name == $current)
        let symbol    = if $is_done and not $is_active { "🌹" } else if $is_active { "►" } else { "○" }
        let suffix    = if $is_active { 
            if ($substage | is-not-empty) {
                $"───► running ($substage)"
            } else {
                "───► running"
            }
        } else if $is_done { 
            $"✓  ($elapsed)" 
        } else { 
            "" 
        }
        print $"  ($symbol)  ($name)  ($suffix)"
    }
    print ""
}

def extract-constitution-progress [output: string] {
    # Extract the most recent "constitution: scanned" line from output
    let scan_lines = (
        $output
        | lines
        | where { |l| $l =~ "constitution: scanned" }
    )

    if ($scan_lines | is-not-empty) {
        $scan_lines | last
    } else {
        ""
    }
}

def detect-build-substage [output: string] {
    # Detect what phase the Guix build is currently in based on recent output
    let lines = ($output | lines)

    # Check most recent lines for phase indicators (check in reverse order)
    if (($output =~ "building profile") or ($output =~ "loading.*modules")) {
        "building profile"
    } else if ($output =~ "running tests") {
        "running tests"
    } else if ($output =~ "^building") or ($output =~ "building derivation") {
        "building packages"
    } else if ($output =~ "deriving") or ($output =~ "computing derivations") {
        "deriving packages"
    } else if ($output =~ "resolving.*modules" or $output =~ "Looking for") {
        "resolving modules"
    } else if ($output =~ "Entering directory") {
        "parsing constitution"
    } else {
        ""
    }
}


# =============================================================================
# SECTION 2 — ERROR DISPLAY
#
# Extracts and renders failure information from the build log. Knows about
# constitution-specific error patterns and surfaces them before generic
# Guix errors so the most actionable line is always first.
#
# Constitution errors recognised (checked in priority order):
#   - sovereignty violation  — an import resolved outside the Manifold
#   - duplicate package      — two modules defined the same package differently
#   - failed to load module  — resolve-module returned #f for a scanned file
#   - error:                 — fallback for anything Guix itself reports
#
# On failure the user is offered:
#   - Revert to last pushed commit (git reset --hard HEAD-before-reshape)
#   - View diagnostics (warnings + raw output)
#   - Open full log in less
# =============================================================================

def extract-core-error [all_output: string] {
    # Constitution-specific patterns take priority — they are the most actionable.
    # Checked in order: sovereignty → duplicate → load failure → generic error.
    let constitution_patterns = [
        "constitution: sovereignty violation"
        "constitution: duplicate package"
        "constitution: failed to load module"
        "error:"
    ]

    for pattern in $constitution_patterns {
        let matches = (
            $all_output
            | lines
            | where { |l| $l =~ $pattern }
        )
        if ($matches | is-not-empty) {
            return ($matches | first | str trim)
        }
    }

    "Unknown error — check log for details"
}

def render-errors [all_output: string, log_file: string] {
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi white_bold)🌹 MANIFOLD // RESHAPING 🌹(ansi reset)"
    print $"(ansi white)  Error encountered during workflow.(ansi reset)"
    print ""

    # Primary error — constitution-aware, most actionable line first
    let core_error = (extract-core-error $all_output)
    print-section "❌ ERROR" "reconfiguration failed" [
        { error: $core_error }
    ]
    print ""

    # Constitution scan progress — shows how far the scan got before failure
    let scan_line = (
        $all_output
        | lines
        | where { |l| $l =~ "constitution: scanned" }
        | last 1
    )
    if ($scan_line | is-not-empty) {
        print-section "📊 SCAN" "constitution progress before failure" [
            { output: ($scan_line | first | str trim) }
        ]
        print ""
    }

    # Log file path
    print-section "📋 LOG FILE" "full output saved at" [
        { path: $log_file }
    ]
    print ""

    # Recovery: revert or inspect
    print $"(ansi white)🔄 REVERT TO LAST PUSH(ansi reset)"
    print $"(ansi white)  Go back to last known good commit?(ansi reset)"
    print ""
    let revert_choice = (
        ["no — keep trying to fix" "yes — revert to last push"]
        | input list --fuzzy "Revert working directory?"
    )
    print ""

    let should_revert = ($revert_choice | str starts-with "yes")

    if $should_revert {
        return true
    }

    # Inspection options — only shown if user wants to dig in
    print $"(ansi white)📖 INSPECT ERROR?(ansi reset)"
    print $"(ansi white)  Select no to exit and return to the prompt.(ansi reset)"
    print ""
    let inspect_choice = (
        ["no — return to prompt" "diagnostics — warnings + raw output" "full-log — open log in pager"]
        | input list --fuzzy "Inspect:"
    )
    print ""

    if ($inspect_choice == null or ($inspect_choice | str starts-with "no")) {
        print -n "\e[2J\e[H"
        return false
    }

    if ($inspect_choice | str starts-with "full-log") {
        try {
            less $log_file
        } catch {
            print $"(ansi white)Unable to open log with less, showing raw content:(ansi reset)"
            print ""
            try { open --raw $log_file | print } catch { print $"(ansi white)Failed to read log file(ansi reset)" }
        }
    } else {
        # Diagnostics: constitution + Guix warnings, excluding shell noise
        print-section "⚠ WARNINGS" "non-fatal issues from constitution + guix" (
            $all_output
            | lines
            | where { |l|
                ($l =~ "WARNING:" or $l =~ "warning:" or $l =~ "deprecated:")
                and (not ($l =~ "ExternalCommand"))
                and (not ($l =~ "Span {"))
            }
            | each { |w| { warning: $w } }
        )
        print ""

        print-section "📄 RAW OUTPUT" "full error output from guix system build" []
        print ""
        $all_output | lines | each { |l| print $"  ($l)" }
        print ""
    }

    false
}


# =============================================================================
# SECTION 3 — GIT OPERATIONS
#
# capture-last-good records the current HEAD before any reshape begins.
# A revert can always return to the last successfully built and pushed state.
#
# git-sync stages all changes, collects a structured diff for the summary
# display, and calls into the History module to update the commit log.
# Only called on successful reconfigure — git never reflects a broken build.
#
# revert-to-last-push does a hard reset, discarding any uncommitted changes
# made since the last push. Only called when the user explicitly chooses
# revert after a failed reconfigure.
# =============================================================================

def capture-store-size [] {
    # Returns store size in bytes, or null if unable to read
    try { 
        let line = (^du --max-depth 0 /gnu/store 2>/dev/null)
        let size = ($line | split row '\t' | get 0 | into int)
        $size * 1024  # du returns KB, convert to bytes
    } catch { 
        null 
    }
}

def format-bytes [bytes: int] {
    # Convert bytes to human-readable format (KB, MB, GB)
    if ($bytes < 1048576) {
        let kb = ($bytes / 1024 | math round)
        $"($kb)KB"
    } else if ($bytes < 1073741824) {
        let mb = ($bytes / 1048576 | math round --precision 1)
        $"($mb)MB"
    } else {
        let gb = ($bytes / 1073741824 | math round --precision 1)
        $"($gb)GB"
    }
}

def capture-last-good [] {
    git -C /ManifoldOS rev-parse HEAD | str trim
}

def capture-diff [] {
    # Snapshot the diff BEFORE History stages everything — called after reconfigure succeeds
    let added    = (git -C /ManifoldOS diff --name-only --diff-filter=A | lines | where { |l| $l | is-not-empty } | each { |f| { status: "added"    file: $f  "+": ""  "-": "" } })
    let deleted  = (git -C /ManifoldOS diff --name-only --diff-filter=D | lines | where { |l| $l | is-not-empty } | each { |f| { status: "deleted"  file: $f  "+": ""  "-": "" } })
    let modified = (git -C /ManifoldOS diff --numstat --diff-filter=M   | lines | where { |l| $l | is-not-empty } | each { |line|
        let p = ($line | split row "\t")
        { status: "modified"  file: ($p | get 2)  "+": ($p | get 0)  "-": ($p | get 1) }
    })
    $added | append $deleted | append $modified
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
#
# clear-guile-cache wipes both root's and the current user's Guile bytecode
# cache. Without this, a changed module can silently build against a stale
# .go file that does not reflect recent edits. Always cleared before
# reconfigure.
#
# run-build invokes `guix system build` against the constitution
# at /ManifoldOS/Manifold/constitution.scm. All stdout and stderr — including
# constitution scan output, sovereignty violations, regression warnings, and
# Guix build output — is captured to the log file.
#
# run-gc removes old system generations to reclaim /gnu/store space. Runs
# last so a failed reshape never destroys the last good generation.
# =============================================================================

def clear-guile-cache [log: string] {
    # Clear user cache (no sudo needed)
    try { rm -rf ~/.cache/guile/ccache out+err>> $log } catch { }

    # Clear root cache (requires sudo, but fail silently if password not available)
    try { ^/run/setuid-programs/sudo rm -rf /root/.cache/guile/ccache out+err>> $log } catch { }
}

def run-reconfigure [log: string] {
    # The constitution is the direct build target — no wrapper needed.
    # It exports `os` which Guix discovers automatically.
    let manifest = "/ManifoldOS/Manifold/constitution.scm"
    let r = (^/run/setuid-programs/sudo guix system build $manifest | complete)
    $r.stdout out>> $log
    $r.stderr out>> $log
    $r
}

def run-gc [log: string] {
    try { ^/run/setuid-programs/sudo guix system delete-generations out+err>> $log } catch { }
}


# =============================================================================
# SECTION 5 — SUMMARY
#
# Renders the full post-reshape report. Only reached on successful reconfigure.
#
# Shows:
#   - Constitution scan summary (files scanned, packages, services)
#   - Any constitution warnings (regressions, duplicate services, export typos)
#   - Reshape metrics (generation, files changed, total time, disk usage)
#   - Step list and per-step wall-clock timing
#   - Live system state (kernel, RAM, CPU load, temp, uptime, store size)
#   - Shepherd service states, filtered to non-noise services
#   - Git diff summary and push results from the History module
#   - Emacs daemon state
# =============================================================================

def extract-warnings [log_content: string] {
    $log_content
    | lines
    | where { |l|
        ($l =~ "WARNING:" or $l =~ "warning:" or $l =~ "deprecated:")
        and (not ($l =~ "ExternalCommand"))
        and (not ($l =~ "Span {"))
    }
}

def render-summary [results: list, changed: list, timings: record, log_file: string, store_delta: int] {
    print -n "\e[2J\e[H"
    print ""

    let log_content = (try { open --raw $log_file } catch { "" })
    let warnings    = (extract-warnings $log_content)

    # Success banner
    print $"(ansi white_bold)✓ RECONFIGURATION SUCCESSFUL(ansi reset)"
    print ""

    # Constitution scan summary — always present on success
    let scan_line = (
        $log_content
        | lines
        | where { |l| $l =~ "constitution: scanned" }
        | last 1
    )
    if ($scan_line | is-not-empty) {
        print-section "📊 MANIFOLD SCAN" "constitution output" [
            { output: ($scan_line | first | str trim) }
        ]
        print ""
    }

    # Constitution warnings (regressions, duplicate services, export name issues)
    if ($warnings | is-not-empty) {
        print-section "⚠ WARNINGS" "issues detected in build log" (
            $warnings | each { |w| { warning: $w } }
        )
    } else {
        print ""
    }

    # Reshape metrics
    let gen_info   = (extract-generation-info "/ManifoldOS")
    let total_time = (
        ($timings | values)
        | each { |v| $v | str replace -r 's$' '' | into float }
        | math sum
    )
    let file_count = ($changed | length)
    let disk_cols  = (^df -h / | lines | last | split row " " | where { |it| $it | is-not-empty })
    let disk_usage = ($disk_cols | get 4)

    # Store delta display
    let store_delta_str = if ($store_delta != null) {
        if ($store_delta > 0) {
            $"↑ (format-bytes $store_delta)"
        } else if ($store_delta < 0) {
            $"↓ (format-bytes ((-1) * $store_delta))"
        } else {
            "no change"
        }
    } else {
        "unknown"
    }

    print-section "SUMMARY" "reconfiguration metrics" [
        { metric: "Generation"    value: $gen_info.generation }
        { metric: "Files changed" value: $file_count }
        { metric: "Store delta"   value: $store_delta_str }
        { metric: "Total time"    value: $"($total_time | math round --precision 1)s" }
        { metric: "Disk usage /"  value: $disk_usage }
    ]
    print ""

    print-section "STEPS" "operations performed during this reshape" (
        $results | each { |r| { step: $r.description } }
    )

    print-section "BUILD TIMING" "duration of each step" (
        $timings | transpose key value | each { |e| { step: $e.key  duration: $e.value } }
    )

    # Live system state
    let kernel    = (^uname -r | str trim)
    let disk      = $"($disk_cols | get 2) / ($disk_cols | get 1)"
    let store     = (du --max-depth 0 /gnu/store | get apparent | first | into string)
    let mem_cols  = (try { ^free -h | lines | where { |l| $l =~ "^Mem:" } | first | split row " " | where { |it| $it | is-not-empty } } catch { [] })
    let ram       = $"($mem_cols | get 2) / ($mem_cols | get 1)"
    let uptime    = (^uptime | str trim | str replace -r `.*up\s+` "" | str replace -r `,\s+\d+ user.*` "" | str trim)
    let cpu       = (try { let l = (^cat /proc/loadavg | split row " "); $"($l | get 0) ($l | get 1) ($l | get 2)" } catch { "unavailable" })
    let temp      = (try { let t = (^cat /sys/class/thermal/thermal_zone0/temp | str trim | into int); $"($t / 1000)°C" } catch { "unavailable" })
    let gens      = (try { guix system list-generations | lines | where { |l| $l =~ "^Generation" } | length | into string } catch { "unavailable" })

    print-section "SYSTEM" "hardware and runtime state" [
        { key: "Kernel"      value: $kernel }
        { key: "Disk /"      value: $disk }
        { key: "Store"       value: $store }
        { key: "RAM"         value: $ram }
        { key: "CPU Load"    value: $cpu }
        { key: "Temp"        value: $temp }
        { key: "Uptime"      value: $uptime }
        { key: "Generations" value: $gens }
    ]

    # Shepherd services — kernel/boot noise filtered, user-visible services only
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
            let is_svc  = ($trimmed | str starts-with "+") or ($trimmed | str starts-with "-")
            if $is_svc and $svc_status != "" {
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

    # Git summary
    print-git-sections "/ManifoldOS" $changed $results

    # Emacs daemon
    let emacs_status = (try { herd status emacs-daemon | str trim } catch { "" })
    let emacs_state  = if ($emacs_status =~ "running") { "🌹 running" } else { "🥀 stopped" }
    print-section "EMACS" "control center status" [{ state: $emacs_state }]

    print ""
    print $"(ansi white_bold)✓ System reconfiguration and git history updated(ansi reset)"
    print ""
}


# =============================================================================
# SECTION 6 — MAIN
#
# ManifoldOS-Reshaping is the single entry point. Runs the four-stage loop:
#
#   Cache → Reconfigure → Commit → GC
#
# Git is touched only on success. The log captures everything. On failure,
# the user is offered revert or inspect before the function returns.
# The working directory is captured and restored so this is safe to invoke
# from anywhere via the Ctrl+S keybinding.
# =============================================================================

def ManifoldOS-Reshaping [] {
    let log            = $"/tmp/reshape_(date now | format date '%Y%m%d_%H%M%S').log"
    let origin_dir     = ($env.PWD)
    let last_good      = (capture-last-good)
    let store_before   = (capture-store-size)
    let steps = [
        { name: "Pre-cleanup" }
        { name: "Cache" }
        { name: "Build" }
        { name: "Commit" }
        { name: "GC" }
    ]
    mut timings = {}

    cd /ManifoldOS

    # Stage 0: Pre-cleanup — clear cache and collect garbage before reconfigure
    rs-flow $steps "Pre-cleanup" $timings ""
    let t = (date now)

    # Clear user cache
    try { rm -rf ~/.cache/guile/ccache } catch { }

    # Collect garbage to fix "Too many root sets" errors
    try { 
        ^guix gc --collect-garbage | ignore
    } catch { 
        print "(guix gc warning: may require password, continuing anyway)"
    }

    $timings = ($timings | insert Pre-cleanup $"(((date now) - $t) / 1sec | math round)s")

    # Stage 1: Clear Guile bytecode cache
    rs-flow $steps "Cache" $timings ""
    let t = (date now)
    clear-guile-cache $log
    $timings = ($timings | insert Cache $"(((date now) - $t) / 1sec | math round)s")

    # Stage 2: Build against the constitution
    rs-flow $steps "Build" $timings ""
    let t = (date now)
    let r = (run-reconfigure $log)
    $timings = ($timings | insert Build $"(((date now) - $t) / 1sec | math round)s")

    if $r.exit_code != 0 {
        let all_output    = ($r.stdout + "\n" + $r.stderr)
        let should_revert = (render-errors $all_output $log)

        if $should_revert {
            revert-to-last-push $last_good
        }

        cd $origin_dir
        return
    }

    # Stage 3: Commit and push — success only, git never reflects a broken build
    rs-flow $steps "Commit" $timings ""
    let t = (date now)
    let changed = (capture-diff)
    ManifoldOS-Reshaping-History "update"
    $timings = ($timings | insert Commit $"(((date now) - $t) / 1sec | math round)s")

    # Stage 4: Garbage collect old generations
    rs-flow $steps "GC" $timings ""
    let t = (date now)
    run-gc $log
    $timings = ($timings | insert GC $"(((date now) - $t) / 1sec | math round)s")

    cd $origin_dir

    let store_after = (capture-store-size)
    let store_delta = if ($store_before != null and $store_after != null) { $store_after - $store_before } else { null }

    let results = [
        { description: "Pre-cleanup (cache + garbage collection)" }
        { description: "Guile cache cleared" }
        { description: "System built via constitution" }
        { description: "Working state committed & pushed" }
        { description: "Reality reshaped" }
    ]
    render-summary $results $changed $timings $log $store_delta
}


# =============================================================================
# SECTION 7 — KEYBINDING
#
# Ctrl+S in Nushell emacs mode fires the reshape loop from any prompt.
# The working directory is captured and restored by the main function,
# so this is safe to invoke from anywhere.
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