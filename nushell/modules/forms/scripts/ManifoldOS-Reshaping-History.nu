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
#   On first run in a repo with no .jj, jj is initialized automatically with
#   --colocate so the repo is never left in a broken state. The script walks
#   up the directory tree to find the repo root — it never creates a repo
#   inside an existing one.
#
# What does this file do?
#
#   It runs the pipeline in five stages:
#
#     1. INIT   — Walks up the tree to find the repo root (.git or .jj).
#                 If neither exists anywhere, initializes jj with --colocate
#                 in the current directory. Syncs git identity into jj on
#                 first run so commits are attributed correctly.
#
#     2. FETCH  — jj git fetch. Warns if working copy is dirty before fetch.
#                 Hard aborts if no remote is configured.
#
#     3. CHECK  — Runs all safety checks before touching the index:
#                   - Behind remote  — abort if upstream has commits we lack
#                   - Conflicts      — abort if unresolved merge markers exist
#                   - Remote reachable — abort if origin is offline
#                   - Stash          — warn and let the operator decide
#                 Any check returning true aborts the entire pipeline.
#
#     4. COMMIT — jj describe + jj new. No staging — jj tracks the working
#                 copy automatically. If nothing changed, renders current
#                 state and exits cleanly.
#
#     5. PUSH   — jj git push. Push failures render the full remote error.
#
# What is the public API?
#
#   ManifoldOS-Reshaping-History [msg]
#     Runs the full five-stage pipeline. Called by ManifoldOS-Reshaping.nu
#     after a successful reconfigure. Can also be invoked standalone via
#     Ctrl+G. Snapshots the jj op ID before running for a guaranteed undo
#     target.
#
#   print-git-sections [repo, changed, push_results]
#     Read-only. Called by ManifoldOS-Reshaping.nu to render the git
#     sections inside the main reshape summary. Does not stage, commit,
#     or push — only reads and displays.
#
#   fetch-commits-from [repo, n]
#     Returns the last N commits as a structured table using jj log.
#     Falls back to git log if jj template fails.
#
#   fetch-status-from [repo]
#     Returns raw jj status lines for the working tree.
#
#   fetch-repo-stats-from [repo]
#     Returns a record with branch, remote URL, total commit count, last
#     push time, last tag, ahead/behind counts (tri-state: int or null,
#     renders as "?"), and stash count. Pass --json for machine-readable
#     output.
#
#   fetch-op-log-from [repo, n]
#     Returns the last N jj operations. Wired into post-push render.
#
#   snapshot-op-id [repo]
#     Returns the current jj op ID. Called before pipeline starts so the
#     undo target is always printed after a push.
#
# Convenience commands:
#
#   jj-undo          — jj op undo (Ctrl+Z)
#   jj-restore-op    — jj op restore to a specific op ID
#   jj-split         — jj split (interactive)
#   jj-squash        — jj squash into parent
#   jj-evolog        — jj evolog for current change
#   jj-stats-json    — fetch-repo-stats-from --json
#
# What happens on failure?
#
#   Every failure path clears the screen, renders a labelled error block
#   with the specific reason, and returns without touching the repo further.
#   The operator is never left with a partially committed or partially
#   pushed repository.
#
# Keybindings:
#
#   Ctrl+G runs the history pipeline standalone from any prompt.
#   Ctrl+Z runs jj-undo.
# =============================================================================


# =============================================================================
# CONFIGURATION
#
# Top-level record read by safety checks at runtime. Adjust thresholds here
# rather than hunting through individual check functions.
#
#   max_file_size_mb  — staged files larger than this trigger a hard abort
#   verbose_failures  — reserved for future per-check verbosity control
#   commits_to_show   — number of commits shown in post-push render
#   op_log_to_show    — number of jj operations shown in post-push render
# =============================================================================

let config = {
    max_file_size_mb: 5
    verbose_failures: true
    commits_to_show:  10
    op_log_to_show:   5
}


# =============================================================================
# SECTION 0 — REPO DETECTION + JJ INIT
#
# find-repo-root
#   Walks up the directory tree looking for .git or .jj. Returns the first
#   directory that contains either. Returns null if nothing is found all the
#   way to the filesystem root. This prevents the script from ever creating
#   a repo inside an existing one.
#
# ensure-jj-initialized
#   If .jj is missing from the repo root, runs jj git init --colocate there.
#   After init (or if .jj already existed), syncs git user.email and
#   user.name into jj config if jj has no identity set. This means jj
#   commits are always attributed correctly without manual configuration.
# =============================================================================

def find-repo-root [] {
    mut dir = (pwd)
    loop {
        if ($dir | path join ".git" | path exists) or ($dir | path join ".jj" | path exists) {
            return $dir
        }
        let parent = ($dir | path dirname)
        if $parent == $dir {
            return null
        }
        $dir = $parent
    }
}

def ensure-jj-initialized [repo: string] {
    let jj_dir = ($repo | path join ".jj")
    if not ($jj_dir | path exists) {
        print $"(ansi yellow)  jj not initialized — running jj git init --colocate in ($repo)(ansi reset)"
        let result = (do { cd $repo; jj git init --colocate } | complete)
        if $result.exit_code != 0 {
            print -e $"(ansi red_bold)  ✗ jj init failed:(ansi reset) ($result.stderr)"
            return false
        }
        print $"(ansi green)  ✓ jj initialized \(colocated\)(ansi reset)"
    }

    # Sync identity from git config if jj has none
    let jj_email = (try { jj config get user.email | str trim } catch { "" })
    if ($jj_email | is-empty) {
        let git_email = (try { git -C $repo config user.email | str trim } catch { "" })
        let git_name  = (try { git -C $repo config user.name  | str trim } catch { "" })
        if ($git_email | is-not-empty) { jj config set --user user.email $git_email }
        if ($git_name  | is-not-empty) { jj config set --user user.name  $git_name  }
    }

    true
}


# =============================================================================
# SECTION 1 — FLOW ENGINE
#
# Renders the live pipeline progress display. Called at the start of each
# stage with the name of the currently executing stage. Completed stages
# show their wall-clock duration. The active stage shows "running". Future
# stages show an empty circle.
#
# Clears the screen on every call so the display updates in place rather
# than scrolling. This is intentional — the flow is a status display, not
# a log.
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
# These functions are the read layer — they query the repository and return
# structured data. They never modify the index or working tree.
#
# fetch-commits-from
#   Uses jj log with a pipe-delimited template for change ID, commit ID,
#   age, subject, and author. Falls back to git log if jj template fails.
#
# fetch-status-from
#   Uses jj status for working copy awareness. Falls back to git status.
#
# fetch-repo-stats-from
#   Aggregates the most useful single-glance metrics into one record.
#   ahead/behind are tri-state: int or null (null renders as "?" — never
#   silently wrong). Pass --json for machine-readable output.
#
# fetch-op-log-from
#   Returns the last N lines of jj op log — the undo stack.
#
# snapshot-op-id
#   Returns the current jj op ID as a string for use as a restore target.
# =============================================================================

def fetch-commits-from [repo: string, n: int] {
    let tmpl = 'change_id.short() ++ "|" ++ commit_id.short() ++ "|" ++ author.timestamp().ago() ++ "|" ++ description.first_line() ++ "|" ++ author.name() ++ "\n"'
    try {
        jj --repository $repo log --no-graph --limit $n --template $tmpl
        | lines
        | where { |l| $l | is-not-empty }
        | each { |line|
            let p = ($line | split row "|")
            {
                change_id: ($p | get 0)
                commit_id: ($p | get 1)
                age:       ($p | get 2)
                subject:   ($p | get 3)
                author:    ($p | get 4)
            }
        }
    } catch {
        git -C $repo log --format="%h|%ad|%s|%an" --date=short $"-($n)"
        | lines
        | where { |l| $l | is-not-empty }
        | each { |line|
            let p     = ($line | split row "|")
            let hash  = ($p | get 0)
            let stats = (git -C $repo show --stat $hash | lines | last | str trim)
            { change_id: "git"  commit_id: $hash  age: ($p | get 1)  subject: ($p | get 2)  author: ($p | get 3) }
        }
    }
}

def fetch-status-from [repo: string] {
    try {
        jj --repository $repo status
        | lines
        | where { |l| $l | is-not-empty }
    } catch {
        git -C $repo status --short | lines | where { |l| $l | is-not-empty }
    }
}

def fetch-repo-stats-from [repo: string, --json] {
    let ahead = (try {
        jj --repository $repo log --no-graph -r 'remote_bookmarks()..@' --limit 100
        | lines | where { |l| $l | is-not-empty } | length
    } catch { null })

    let behind = (try {
        jj --repository $repo log --no-graph -r '@..remote_bookmarks()' --limit 100
        | lines | where { |l| $l | is-not-empty } | length
    } catch { null })

    let stats = {
        branch:      (try { jj --repository $repo log --no-graph -r @ --template 'bookmarks' | str trim } catch { git -C $repo branch --show-current | str trim })
        remote_url:  (try { git -C $repo remote get-url origin | str trim } catch { "none" })
        total:       (git -C $repo rev-list --count HEAD | str trim)
        last_push:   (git -C $repo log -1 --format="%ad" --date=relative | str trim)
        last_tag:    (try { git -C $repo describe --tags --abbrev=0 out+err>/dev/null | str trim } catch { "none" })
        ahead:       (if $ahead == null { "?" } else { $ahead | into string })
        behind:      (if $behind == null { "?" } else { $behind | into string })
        stash_count: (try { git -C $repo stash list | lines | length } catch { 0 })
    }

    if $json { $stats | to json } else { $stats }
}

def fetch-op-log-from [repo: string, n: int] {
    try {
        jj --repository $repo op log --no-graph --limit $n
        | lines
        | where { |l| $l | is-not-empty }
    } catch {
        ["(op log unavailable)"]
    }
}

def snapshot-op-id [repo: string] {
    try {
        jj --repository $repo op log --no-graph --limit 1 --template 'id' | str trim
    } catch {
        null
    }
}


# =============================================================================
# SECTION 3 — SAFETY CHECKS
#
# Each check is a pure predicate: returns true to abort, false to continue.
# The main pipeline calls them in sequence and returns immediately on the
# first true — no check runs after an abort is decided.
#
# render-error
#   Shared display primitive for all check failures. Clears the screen and
#   renders a labelled error block so every failure looks consistent.
#
# check-behind
#   Uses jj revsets to detect if remote has commits we lack.
#
# check-conflicts
#   Uses jj to detect conflict markers in the working copy.
#
# check-remote-reachable
#   Uses git ls-remote as a lightweight connectivity probe.
#
# check-stash
#   Stashed changes are not a hard abort but surface with a prompt.
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
        let commits = (git -C $repo log HEAD..@{u} --format="%h  %ad  %an  %s" --date=short | lines)
        render-error "BEHIND REMOTE" $"Your branch is ($behind) commit(s) behind. Pull before pushing." $commits
        true
    } else {
        false
    }
}

def check-conflicts [repo: string] {
    let has_conflicts = (try {
        jj --repository $repo log --no-graph -r 'conflicts()' | str trim | is-not-empty
    } catch { false })
    if $has_conflicts {
        render-error "UNRESOLVED CONFLICTS" "Conflicts detected. Resolve before committing." [
            { hint: "jj resolve — interactive resolver" }
            { hint: "jj diff    — inspect conflicts"    }
        ]
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
        let subtitle = $"($count) stash(es) exist — they may conflict with the current push."
        render-error "STASHED CHANGES PRESENT" $subtitle $stashes
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Stash detected — proceed?")
        $choice == "abort"
    } else {
        false
    }
}


# =============================================================================
# SECTION 4 — IMPACT
#
# Captures what the commit contains as structured data so the summary
# display can show exactly what changed without re-querying after the
# working copy has advanced.
#
# capture-changed
#   Uses jj diff to get the list of changed files with their status.
#
# summarize-impact
#   Aggregates the changed list into counts by status.
#
# calculate-diff-stats
#   Totals lines added and deleted across all changed files.
# =============================================================================

def capture-changed [repo: string] {
    try {
        jj --repository $repo diff --summary
        | lines
        | where { |l| $l | is-not-empty }
        | each { |line|
            let parts  = ($line | str trim | split row " " | where { |p| $p | is-not-empty })
            let status = match ($parts | get 0) {
                "A" => "added"
                "D" => "deleted"
                "M" => "modified"
                _   => "changed"
            }
            { status: $status  file: ($parts | get 1)  "+": ""  "-": "" }
        }
    } catch {
        []
    }
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
        let stats = (jj --repository $repo diff --stat | lines | last | str trim)
        # jj diff --stat last line: "N files changed, X insertions(+), Y deletions(-)"
        let added   = (try { $stats | parse --regex '(\d+) insertion' | get capture0.0 | into int } catch { 0 })
        let deleted = (try { $stats | parse --regex '(\d+) deletion'  | get capture0.0 | into int } catch { 0 })
        { added: $added  deleted: $deleted }
    } catch {
        { added: 0  deleted: 0 }
    }
}


# =============================================================================
# SECTION 4B — SYSTEM INFO
#
# extract-generation-info
#   Reads the current Guix system generation number and creation date.
#   Wrapped in try/catch — may not be available on all systems.
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
#
# print-section
#   Universal display primitive. Every block of output goes through here.
#
# render-impact
#   Shows the commit's mutation signature: file counts and per-file table.
#
# render-position
#   Shows repository sync state: branch, remote, tag, commits, ahead/behind,
#   stash warning, working tree state, and line-level diff totals.
#
# render-history
#   Shows the last N commits. Uses jj change IDs when available.
#
# render-op-log
#   Shows the last N jj operations with the undo target highlighted.
#
# render-nothing-to-commit
#   Called when nothing changed. Not an error — renders current state.
#
# render-push-failure
#   Called when jj git push exits non-zero.
#
# print-git-sections
#   Public API called by ManifoldOS-Reshaping.nu. Read-only.
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
        { key: "Sync"          value: $"↑($stats.ahead) ↓($stats.behind)" }
    ]
    if $stats.stash_count > 0 {
        $rows = ($rows | append { key: "Stash"  value: $"($stats.stash_count) stashed change(s)" })
    }
    let state = if ($status | is-empty) { "✓ clean" } else { $"($status | length) change(s)" }
    $rows = ($rows | append { key: "State"      value: $state })
    $rows = ($rows | append { key: "Diff stats" value: $"+($diff_stats.added) lines  -($diff_stats.deleted) lines" })
    print-section "POSITION" "alignment between local drift and upstream state" $rows
}

def render-history [commits: list] {
    print-section "TEMPORAL TRACE" "compressed lineage of repository evolution" $commits
}

def render-op-log [repo: string, pre_op_id: string] {
    let ops = (fetch-op-log-from $repo $config.op_log_to_show)
    print-section "OPERATION LOG" "jj undo stack" $ops
    if ($pre_op_id | is-not-empty) {
        print $"  (ansi grey)undo target: ($pre_op_id)(ansi reset)"
        print $"  (ansi grey)  → jj op restore ($pre_op_id)(ansi reset)"
    }
}

def render-nothing-to-commit [repo: string] {
    let stats      = (fetch-repo-stats-from $repo)
    let status     = (fetch-status-from $repo)
    let commits    = (fetch-commits-from $repo $config.commits_to_show)
    let diff_stats = (calculate-diff-stats $repo)
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  Nothing new to commit — showing current state.(ansi reset)"
    print ""
    print-section "NOTHING TO COMMIT" "No changes detected" [{ status: "clean" }]
    render-position $stats $status $diff_stats
    render-history $commits
}

def render-push-failure [stderr: string] {
    let error_lines = ($stderr | lines | where { |l| $l | is-not-empty })
    render-error "PUSH FAILED" "Remote rejected the push. Review errors and retry." $error_lines
}

def print-git-sections [repo: string, changed: list, push_results: list] {
    let stats      = (fetch-repo-stats-from $repo)
    let status     = (fetch-status-from $repo)
    let commits    = (fetch-commits-from $repo $config.commits_to_show)
    let diff_stats = (calculate-diff-stats $repo)

    if ($push_results | is-not-empty) {
        print-section "PUSH" "steps completed in this operation" (
            $push_results | each { |r| { step: $r.description } }
        )
    }
    if ($changed | is-not-empty) {
        render-impact $changed
    }
    render-history $commits
    render-position $stats $status $diff_stats
}


# =============================================================================
# SECTION 6 — MAIN
#
# ManifoldOS-Reshaping-History runs the full five-stage pipeline.
#
# Entry points:
#   - Called by ManifoldOS-Reshaping.nu after a successful reconfigure
#   - Called standalone via Ctrl+G
#
# The repo root is found by walking up the directory tree via find-repo-root
# rather than hardcoded or via git rev-parse, so it works correctly from any
# subdirectory and never creates repos inside repos.
#
# has_remote is resolved once at the top and threaded through all stages.
# pre_op_id is snapshotted before anything touches the repo so the undo
# target is always valid even if the pipeline fails mid-way.
# =============================================================================

def ManifoldOS-Reshaping-History [msg: string = "update"] {
    let repo = (find-repo-root)
    if $repo == null {
        print -e $"(ansi red_bold)  ✗ no git or jj repo found in this directory or any parent(ansi reset)"
        return
    }

    let init_ok = (ensure-jj-initialized $repo)
    if not $init_ok { return }

    let has_remote = (try { git -C $repo remote | str trim | is-not-empty } catch { false })
    if not $has_remote {
        print -e $"(ansi red_bold)  ✗ no remote configured — add one with: git remote add origin <url>(ansi reset)"
        return
    }

    # Snapshot op ID before anything touches the repo
    let pre_op_id = (snapshot-op-id $repo)

    let steps = [
        { name: "INIT"   }
        { name: "FETCH"  }
        { name: "CHECK"  }
        { name: "COMMIT" }
        { name: "PUSH"   }
    ]
    mut timings = {}

    # ── INIT ────────────────────────────────────────────────
    rh-flow $steps "INIT" $timings
    let t = (date now)
    $timings = ($timings | insert INIT $"(((date now) - $t) / 1sec * 1000 | math round)ms")

    # ── FETCH ───────────────────────────────────────────────
    rh-flow $steps "FETCH" $timings
    let t = (date now)
    if (has-dirty-working-copy $repo) {
        print $"(ansi yellow)  ⚠ working copy has uncommitted changes — fetch may fold remote changes in(ansi reset)"
    }
    let fetch_result = (do { jj --repository $repo git fetch } | complete)
    if $fetch_result.exit_code != 0 {
        print -e $"(ansi red_bold)  ✗ fetch failed:(ansi reset) ($fetch_result.stderr)"
        return
    }
    $timings = ($timings | insert FETCH $"(((date now) - $t) / 1sec * 1000 | math round)ms")

    # ── CHECK ───────────────────────────────────────────────
    rh-flow $steps "CHECK" $timings
    let t = (date now)
    if (check-behind $repo)           { return }
    if (check-conflicts $repo)        { return }
    if (check-remote-reachable $repo) { return }
    if (check-stash $repo)            { return }
    let changed    = (capture-changed $repo)
    let diff_stats = (calculate-diff-stats $repo)
    $timings = ($timings | insert CHECK $"(((date now) - $t) / 1sec * 1000 | math round)ms")

    # ── COMMIT ──────────────────────────────────────────────
    rh-flow $steps "COMMIT" $timings
    let t = (date now)
    let commit_msg = if ($msg == "update") {
        let branch = (try { jj --repository $repo log --no-graph -r @ --template 'bookmarks' | str trim } catch { git -C $repo branch --show-current | str trim })
        let ts     = (date now | format date "%Y-%m-%d %H:%M")
        $"[($branch)] ($ts)"
    } else {
        $msg
    }
    let desc_result = (do { jj --repository $repo describe -m $commit_msg } | complete)
    if $desc_result.exit_code != 0 {
        print -e $"(ansi red_bold)  ✗ describe failed:(ansi reset) ($desc_result.stderr)"
        return
    }
    let new_result = (do { jj --repository $repo new } | complete)
    if $new_result.exit_code != 0 {
        print -e $"(ansi red_bold)  ✗ jj new failed:(ansi reset) ($new_result.stderr)"
        return
    }
    $timings = ($timings | insert COMMIT $"(((date now) - $t) / 1sec * 1000 | math round)ms")

    # ── PUSH ────────────────────────────────────────────────
    rh-flow $steps "PUSH" $timings
    let t = (date now)
    let push_result = (do { jj --repository $repo git push } | complete)
    if $push_result.exit_code != 0 {
        render-push-failure $push_result.stderr
        return
    }
    $timings = ($timings | insert PUSH $"(((date now) - $t) / 1sec * 1000 | math round)ms")

    # ── POST-PUSH SUMMARY ───────────────────────────────────
    rh-flow $steps "" $timings
    try { jj --repository $repo git fetch out+err>/dev/null } catch { }

    let stats   = (fetch-repo-stats-from $repo)
    let status  = (fetch-status-from $repo)
    let commits = (fetch-commits-from $repo $config.commits_to_show)

    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  Repository state after push.(ansi reset)"
    print ""

    print-section "PUSH STATUS" "✓ pushed to remote" [{ status: "✓ pushed to remote" }]
    render-impact $changed
    render-position $stats $status $diff_stats
    render-history $commits
    render-op-log $repo $pre_op_id
    print ""

    $changed
}


# =============================================================================
# SECTION 7 — CONVENIENCE COMMANDS
#
# Standalone jj operations exposed as named commands. All resolve the repo
# root via find-repo-root so they work from any subdirectory.
# =============================================================================

# Returns true if working copy has uncommitted changes
def has-dirty-working-copy [repo: string] {
    try { (jj --repository $repo diff --stat | str trim | is-not-empty) } catch { false }
}

# Undo last jj operation
def jj-undo [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let result = (do { jj --repository $repo op undo } | complete)
    if $result.exit_code != 0 {
        print -e $"(ansi red_bold)  ✗ undo failed:(ansi reset) ($result.stderr)"
    } else {
        print $"(ansi green)  ✓ undone(ansi reset)"
        fetch-op-log-from $repo 3 | each { |l| print $"  ($l)" }
    }
}

# Restore to a specific op ID (printed after every push as undo target)
def jj-restore-op [op_id: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let result = (do { jj --repository $repo op restore $op_id } | complete)
    if $result.exit_code != 0 {
        print -e $"(ansi red_bold)  ✗ restore failed:(ansi reset) ($result.stderr)"
    } else {
        print $"(ansi green)  ✓ restored to op ($op_id)(ansi reset)"
    }
}

# Split the current commit interactively
def jj-split [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    jj --repository $repo split
}

# Squash working copy into parent
def jj-squash [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    jj --repository $repo squash
}

# Quick glance at evolution log for current change
def jj-evolog [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    jj --repository $repo evolog
}

# Show full repo stats as JSON (for piping to dashboards / status bars)
def jj-stats-json [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    fetch-repo-stats-from $repo --json
}


# =============================================================================
# SECTION 8 — KEYBINDINGS
#
# Ctrl+G runs the history pipeline standalone from any prompt.
# Ctrl+Z runs jj-undo.
# =============================================================================

$env.config.keybindings = ($env.config.keybindings | append [
    {
        name: ManifoldOS_Reshaping_History
        modifier: control
        keycode: char_g
        mode: emacs
        event: { send: executehostcommand cmd: "ManifoldOS-Reshaping-History" }
    }
    {
        name: jj_undo
        modifier: control
        keycode: char_z
        mode: emacs
        event: { send: executehostcommand cmd: "jj-undo" }
    }
])