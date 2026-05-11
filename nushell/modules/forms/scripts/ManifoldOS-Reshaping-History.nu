# =============================================================================
# ManifoldOS — Reshaping History
#
# What is this file?
#
#   This is the git/jj layer of the ManifoldOS reshape loop. It owns everything
#   that happens to the repository after a successful reconfigure: safety
#   checks, committing, pushing, and rendering the post-push state.
#
#   jj is used for working copy management, commit description, and operation
#   log. git (via colocated mode) remains intact so Magit and other git tools
#   continue to work without modification.
#
#   On first run in a repo, jj is initialized automatically with --colocate
#   so the repo is never left in a broken state.
#
# Pipeline stages:
#
#   1. INIT    — Ensures jj is initialized in the repo (colocated). No-op if
#                already set up.
#
#   2. FETCH   — jj git fetch (reflected in git immediately)
#
#   3. CHECK   — Safety checks against upstream state using jj revsets
#
#   4. COMMIT  — jj describe + jj new (no staging — jj tracks working copy)
#
#   5. PUSH    — jj git push
#
# Public API:
#
#   ManifoldOS-Reshaping-History [msg]
#     Full pipeline. Called by ManifoldOS-Reshaping.nu after reconfigure,
#     or standalone via Ctrl+G.
#
#   print-git-sections [repo, changed, push_results]
#     Read-only render of git/jj state. Called by ManifoldOS-Reshaping.nu.
#
#   fetch-commits-from [repo, n]
#     Last N commits as structured table.
#
#   fetch-status-from [repo]
#     Raw jj status lines for working copy.
#
#   fetch-repo-stats-from [repo]
#     Single-glance repo metrics record.
#
# Keybinding:
#
#   Ctrl+G runs the history pipeline standalone from any prompt.
# =============================================================================


# =============================================================================
# CONFIGURATION
# =============================================================================

let config = {
    max_file_size_mb: 5
    verbose_failures: true
}


# =============================================================================
# SECTION 0 — JJ INIT
#
# Ensures jj is colocated in the repo before any operation runs.
# If .jj already exists, this is a no-op. If not, runs jj git init --colocate
# so jj and git share the same object store going forward.
# =============================================================================

def ensure-jj-initialized [repo: string] {
    let jj_dir = ($repo | path join ".jj")
    if not ($jj_dir | path exists) {
        print $"(ansi yellow)  jj not initialized in this repo — running jj git init --colocate(ansi reset)"
        let result = (do { cd $repo; jj git init --colocate } | complete)
        if $result.exit_code != 0 {
            print $"(ansi red_bold)  ✗ jj init failed:(ansi reset) ($result.stderr)"
            return false
        }
        print $"(ansi green)  ✓ jj initialized \(colocated\)(ansi reset)"
    }
    true
}


# =============================================================================
# SECTION 1 — FLOW ENGINE
# =============================================================================

def rh-flow [steps: list, current: string, timings: record] {
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  A staged collapse of repository time.(ansi reset)"
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
# SECTION 2 — DATA COLLECTION (public API)
#
# fetch-commits-from   — last N commits via git log (git stays source of truth
#                        for history so Magit sees the same data)
# fetch-status-from    — jj status for working copy awareness
# fetch-repo-stats-from — combined jj + git metrics
# fetch-op-log-from    — jj operation log (jj-native, no git equivalent)
# =============================================================================

def fetch-commits-from [repo: string, n: int] {
    git -C $repo log --format="%h|%ad|%s|%an" --date=short $"-($n)"
    | lines
    | where { |l| $l | is-not-empty }
    | each { |line|
        let p     = ($line | split row "|")
        let hash  = ($p | get 0)
        let stats = (git -C $repo show --stat $hash | lines | last | str trim)
        { hash: $hash  date: ($p | get 1)  subject: ($p | get 2)  author: ($p | get 3)  changes: $stats }
    }
}

def fetch-status-from [repo: string] {
    # Use jj status for working copy — richer than git status in colocated mode
    try {
        jj --repository $repo status
        | lines
        | where { |l| $l | is-not-empty }
    } catch {
        git -C $repo status --short | lines | where { |l| $l | is-not-empty }
    }
}

def fetch-repo-stats-from [repo: string] {
    let ahead  = (try {
        jj --repository $repo log --no-graph -r 'remote_bookmarks()..@' --limit 100
        | lines | where { |l| $l | is-not-empty } | length
    } catch { 0 })

    let behind = (try {
        jj --repository $repo log --no-graph -r '@..remote_bookmarks()' --limit 100
        | lines | where { |l| $l | is-not-empty } | length
    } catch { 0 })

    {
        branch:      (git -C $repo branch --show-current | str trim)
        remote_url:  (try { git -C $repo remote get-url origin | str trim } catch { "none" })
        total:       (git -C $repo rev-list --count HEAD | str trim)
        last_push:   (git -C $repo log -1 --format="%ad" --date=relative | str trim)
        last_tag:    (try { git -C $repo describe --tags --abbrev=0 out+err> /dev/null | str trim } catch { "none" })
        ahead:       $ahead
        behind:      $behind
        stash_count: (try { git -C $repo stash list | lines | length } catch { 0 })
    }
}

def fetch-op-log-from [repo: string, n: int] {
    try {
        jj --repository $repo op log --no-graph --limit $n
        | lines
        | where { |l| $l | is-not-empty }
        | each { |line| { operation: $line } }
    } catch {
        []
    }
}


# =============================================================================
# SECTION 3 — SAFETY CHECKS
#
# check-behind      — uses jj revsets instead of git rev-list
# check-conflicts   — uses jj revsets: conflict() function
# check-remote-reachable — git ls-remote (network probe, unchanged)
# check-stash       — git stash (unchanged, Magit users may use this)
# check-large-files — git diff --cached (unchanged)
# check-nothing-to-commit — jj status check
# =============================================================================

def render-error [title: string, subtitle: string, details: any] {
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  Error encountered during workflow.(ansi reset)"
    print ""
    print-section $title $subtitle $details
    print ""
}

def check-behind [repo: string] {
    let behind = (try {
        jj --repository $repo log --no-graph -r '@..remote_bookmarks()' --limit 100
        | lines | where { |l| $l | is-not-empty } | length
    } catch { 0 })

    if $behind > 0 {
        let commits = (try {
            jj --repository $repo log --no-graph -r '@..remote_bookmarks()'
            | lines | where { |l| $l | is-not-empty }
            | each { |l| { commit: $l } }
        } catch { [] })
        render-error "BEHIND REMOTE" $"Your branch is ($behind) commit(s) behind. Pull before pushing." $commits
        true
    } else {
        false
    }
}

def check-conflicts [repo: string] {
    let conflicts = (try {
        jj --repository $repo log --no-graph -r 'conflict()'
        | lines | where { |l| $l | is-not-empty }
    } catch { [] })

    if ($conflicts | is-not-empty) {
        render-error "UNRESOLVED CONFLICTS" "Conflicted commits detected. Resolve them before pushing." (
            $conflicts | each { |l| { commit: $l } }
        )
        true
    } else {
        false
    }
}

def check-remote-reachable [repo: string] {
    let result = (try { git -C $repo ls-remote --exit-code origin HEAD | complete } catch { { exit_code: 1 } })
    if $result.exit_code != 0 {
        render-error "REMOTE UNREACHABLE" "Cannot reach origin. Check your network connection." [{ status: "offline" }]
        true
    } else {
        false
    }
}

def check-stash [repo: string] {
    let count = (try { git -C $repo stash list | lines | length } catch { 0 })
    if $count > 0 {
        let stashes  = (git -C $repo stash list | lines)
        let subtitle = $"($count) stash\(es\) exist — they may conflict with the current push."
        render-error "STASHED CHANGES PRESENT" $subtitle $stashes
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Stash detected — proceed?")
        $choice == "abort"
    } else {
        false
    }
}

def check-large-files [repo: string, threshold_mb: int = 5] {
    let threshold = ($threshold_mb * 1000000)
    let large = (
        git -C $repo diff --cached --name-only
        | lines
        | where { |f| $f | is-not-empty }
        | where { |f|
            let full = ($repo | path join $f)
            if ($full | path exists) {
                (ls $full | get size | first | into int) > $threshold
            } else { false }
        }
    )
    if ($large | is-not-empty) {
        render-error "LARGE FILES STAGED" $"Files exceed ($threshold_mb)MB limit. Remove them before pushing." (
            $large | each { |f|
                let full    = ($repo | path join $f)
                let size_mb = ((ls $full | get 0.size | into int | into float) / 1000000 | math round --precision 2)
                { file: $f  size_mb: $size_mb  limit_mb: $threshold_mb }
            }
        )
        true
    } else {
        false
    }
}

def check-nothing-to-commit [repo: string] {
    # jj working copy is always a commit — check if it has any changes
    let status = (try {
        jj --repository $repo diff --stat
        | lines | where { |l| $l | is-not-empty }
    } catch { [] })
    $status | is-empty
}


# =============================================================================
# SECTION 4 — IMPACT
# =============================================================================

def capture-changed [repo: string] {
    let added = (
        git -C $repo diff --cached --name-only --diff-filter=A
        | lines | where { |l| $l | is-not-empty }
        | each { |f| { status: "added"  file: $f  "+": ""  "-": "" } }
    )
    let deleted = (
        git -C $repo diff --cached --name-only --diff-filter=D
        | lines | where { |l| $l | is-not-empty }
        | each { |f| { status: "deleted"  file: $f  "+": ""  "-": "" } }
    )
    let modified = (
        git -C $repo diff --cached --numstat --diff-filter=M
        | lines | where { |l| $l | is-not-empty }
        | each { |line|
            let p = ($line | split row "\t")
            { status: "modified"  file: ($p | get 2)  "+": ($p | get 0)  "-": ($p | get 1) }
        }
    )
    $added | append $deleted | append $modified
}

def summarize-impact [changed: list] {
    {
        files:    ($changed | length)
        added:    ($changed | where status == "added"    | length)
        deleted:  ($changed | where status == "deleted"  | length)
        modified: ($changed | where status == "modified" | length)
    }
}

def calculate-diff-stats [repo: string] {
    try {
        let stats         = (git -C $repo diff --cached --numstat | lines | where { |l| $l | is-not-empty })
        let total_added   = ($stats | each { |l| ($l | split row "\t" | get 0) | into int } | math sum)
        let total_deleted = ($stats | each { |l| ($l | split row "\t" | get 1) | into int } | math sum)
        { added: $total_added  deleted: $total_deleted }
    } catch {
        { added: 0  deleted: 0 }
    }
}


# =============================================================================
# SECTION 4B — SYSTEM INFO
# =============================================================================

def extract-generation-info [repo: string] {
    try {
        let gen_output = (guix system list-generations | lines | first)
        let parts      = ($gen_output | split row " " | where { |it| $it | is-not-empty })
        { generation: ($parts | get 1)  date: ($parts | range 2..4 | str join " ") }
    } catch {
        { generation: "unknown"  date: "unknown" }
    }
}


# =============================================================================
# SECTION 5 — RENDERING
# =============================================================================

def print-section [label: string, subtitle: string, rows: any] {
    print ""
    print $"(ansi red_bold)  ($label)(ansi reset)"
    print $"(ansi grey)  ($subtitle)(ansi reset)"
    if ($rows | is-empty) {
        print $"(ansi grey)  —(ansi reset)"
    } else {
        $rows | print
    }
}

def render-impact [changed: list] {
    let impact = (summarize-impact $changed)
    print-section "IMPACT" "structural mutation signature of this commit" [
        { files: $impact.files  added: $impact.added  deleted: $impact.deleted  modified: $impact.modified }
    ]
    if ($changed | is-not-empty) {
        $changed | print
    }
}

def render-position [stats: record, status: list, diff_stats: record] {
    mut rows = [
        { key: "Branch"        value: $stats.branch }
        { key: "Remote"        value: $stats.remote_url }
        { key: "Tag"           value: $stats.last_tag }
        { key: "Total commits" value: $stats.total }
        { key: "Last push"     value: $stats.last_push }
        { key: "Sync"          value: $"+($stats.ahead) ahead  -($stats.behind) behind" }
    ]
    if $stats.stash_count > 0 {
        $rows = ($rows | append { key: "Stash"  value: $"($stats.stash_count) stashed change(s)" })
    }
    let state = if ($status | is-empty) { "✓ clean" } else { $"($status | length) changes" }
    $rows = ($rows | append { key: "State"      value: $state })
    $rows = ($rows | append { key: "Diff stats" value: $"+($diff_stats.added) lines  -($diff_stats.deleted) lines" })
    print-section "POSITION" "alignment between local drift and upstream state" $rows
}

def render-history [commits: list] {
    print-section "TEMPORAL TRACE" "compressed lineage of repository evolution" $commits
}

def render-op-log [ops: list] {
    print-section "OPERATION LOG" "jj operations that reshaped this repository" $ops
}

def render-nothing-to-commit [repo: string] {
    let stats      = (fetch-repo-stats-from $repo)
    let status     = (fetch-status-from $repo)
    let commits    = (fetch-commits-from $repo 10)
    let diff_stats = (calculate-diff-stats $repo)
    let ops        = (fetch-op-log-from $repo 5)

    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  Nothing new to commit — showing current state.(ansi reset)"
    print ""
    print-section "NOTHING TO COMMIT" "No changes detected in working copy" [{ status: "clean" }]
    render-position $stats $status $diff_stats
    render-history $commits
    render-op-log $ops
}

def render-push-failure [stderr: string] {
    let error_lines = ($stderr | lines | where { |l| $l | is-not-empty })
    render-error "PUSH FAILED" "Remote rejected the push. Review errors and retry." $error_lines
}

def print-git-sections [repo: string, changed: list, push_results: list] {
    let stats      = (fetch-repo-stats-from $repo)
    let status     = (fetch-status-from $repo)
    let commits    = (fetch-commits-from $repo 10)
    let diff_stats = (calculate-diff-stats $repo)
    let ops        = (fetch-op-log-from $repo 5)

    if ($push_results | is-not-empty) {
        print-section "PUSH" "steps completed in this operation" (
            $push_results | each { |r| { step: $r.description } }
        )
    }
    if ($changed | is-not-empty) {
        render-impact $changed
    }
    render-history $commits
    render-op-log $ops
    render-position $stats $status $diff_stats
}


# =============================================================================
# SECTION 6 — MAIN
#
# Five-stage pipeline using jj for working copy + push, git for history
# display so Magit continues to work without any changes.
#
# jj commit flow:
#   - jj describe -m $msg   — sets message on current working copy commit
#   - jj new                — advances @ to a fresh empty commit
#   - jj git push           — pushes to remote
#
# git remains intact underneath for Magit and any other git tooling.
# =============================================================================

def ManifoldOS-Reshaping-History [msg: string = "update"] {
    let repo = (try { git rev-parse --show-toplevel | str trim } catch {
        print $"(ansi red_bold)  ✗ Not a git repository(ansi reset)"
        return
    })

    let has_remote = (try { git -C $repo remote get-url origin | str trim } catch { "" } | is-not-empty)

    let steps = [
        { name: "Init" }
        { name: "Fetch" }
        { name: "Check" }
        { name: "Commit" }
        { name: "Push" }
    ]
    mut timings = {}

    # --- Init --- ensure jj is colocated
    rh-flow $steps "Init" $timings
    let t = (date now)
    if not (ensure-jj-initialized $repo) { return }
    $timings = ($timings | insert Init $"(((date now) - $t) / 1sec | math round)s")

    # --- Fetch ---
    rh-flow $steps "Fetch" $timings
    let t = (date now)
    try { jj --repository $repo git fetch out+err> /dev/null } catch { }
    $timings = ($timings | insert Fetch $"(((date now) - $t) / 1sec | math round)s")

    # --- Safety checks ---
    rh-flow $steps "Check" $timings
    let t = (date now)
    if (check-behind $repo)                           { return }
    if (check-conflicts $repo)                        { return }
    if $has_remote and (check-remote-reachable $repo) { return }
    if (check-stash $repo)                            { return }
    $timings = ($timings | insert Check $"(((date now) - $t) / 1sec | math round)s")

    # --- Commit ---
    rh-flow $steps "Commit" $timings
    let t = (date now)

    if (check-nothing-to-commit $repo) {
        render-nothing-to-commit $repo
        return
    }

    # Capture diff before jj advances the working copy commit
    # We stage via git add so git index reflects reality for Magit
    git -C $repo add --all
    if (check-large-files $repo $config.max_file_size_mb) { return }
    let changed    = (capture-changed $repo)
    let diff_stats = (calculate-diff-stats $repo)

    # jj describe sets the commit message on the working copy commit
    let desc_result = (jj --repository $repo describe -m $msg | complete)
    if $desc_result.exit_code != 0 {
        render-nothing-to-commit $repo
        return
    }

    # jj new advances @ to a fresh empty commit, finalizing the previous one
    jj --repository $repo new out+err> /dev/null

    $timings = ($timings | insert Commit $"(((date now) - $t) / 1sec | math round)s")

    # --- Push ---
    rh-flow $steps "Push" $timings
    let t = (date now)
    let push_result = if $has_remote {
        jj --repository $repo git push | complete
    } else {
        { exit_code: 0, stderr: "" }
    }
    $timings = ($timings | insert Push $"(((date now) - $t) / 1sec | math round)s")

    if $push_result.exit_code != 0 {
        render-push-failure $push_result.stderr
        return
    }

    # --- Post-push summary ---
    rh-flow $steps "" $timings
    try { jj --repository $repo git fetch out+err> /dev/null } catch { }

    let stats   = (fetch-repo-stats-from $repo)
    let status  = (fetch-status-from $repo)
    let commits = (fetch-commits-from $repo 10)
    let ops     = (fetch-op-log-from $repo 5)

    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  Repository state after push.(ansi reset)"
    print ""

    let push_status = if $has_remote { "✓ pushed to remote" } else { "✓ committed locally (no remote configured)" }
    print-section "PUSH STATUS" $push_status [{ status: $push_status }]

    render-impact $changed
    render-position $stats $status $diff_stats
    render-history $commits
    render-op-log $ops
    print ""

    $changed
}


# =============================================================================
# SECTION 7 — KEYBINDING
# =============================================================================

$env.config.keybindings = ($env.config.keybindings | append {
    name: ManifoldOS_Reshaping_History
    modifier: control
    keycode: char_g
    mode: emacs
    event: {
        send: executehostcommand
        cmd: "ManifoldOS-Reshaping-History"
    }
})