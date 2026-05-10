# =============================================================================
# ManifoldOS — Reshaping History
#
# What is this file?
#
#   This is the git layer of the ManifoldOS reshape loop. It owns everything
#   that happens to the repository after a successful reconfigure: safety
#   checks, staging, committing, pushing, and rendering the post-push state.
#
#   It is intentionally decoupled from the reconfigure layer. This file never
#   knows whether a reconfigure succeeded or failed — it is simply called by
#   ManifoldOS-Reshaping.nu when the system is clean and ready to persist.
#   That separation is the guarantee that git never reflects a broken build.
#
# What does this file do?
#
#   It runs the git pipeline in five stages:
#
#     1. FETCH  — Pulls remote refs so safety checks have current data.
#                 Does not merge. Failures are silently swallowed — a fetch
#                 failure is not a reason to abort a commit.
#
#     2. CHECK  — Runs all safety checks before touching the index:
#                   - Behind remote  — abort if upstream has commits we lack
#                   - Conflicts      — abort if unresolved merge markers exist
#                   - Remote reachable — abort if origin is offline
#                   - Stash          — warn and let the operator decide
#                 Any check returning true aborts the entire pipeline.
#                 Nothing is staged until all checks pass.
#
#     3. STAGE  — Runs `git add --all` and checks for oversized files.
#                 Captures the structured diff (added/deleted/modified) and
#                 line-level stats before committing so the summary display
#                 has accurate data even after the index advances.
#
#     4. COMMIT — Commits with the message passed by the caller. If nothing
#                 is staged (clean working tree after a reconfigure that
#                 touched no files), renders the current repo state and exits
#                 cleanly — this is not an error.
#
#     5. PUSH   — Pushes to origin if a remote is configured. If no remote
#                 exists, skips silently and reports local-only commit.
#                 Push failures render the full remote error and abort.
#
# What is the public API?
#
#   ManifoldOS-Reshaping-History [msg]
#     Runs the full five-stage pipeline. Called by ManifoldOS-Reshaping.nu
#     after a successful reconfigure. Can also be invoked standalone via
#     Ctrl+G for committing config-only or file-only changes without
#     triggering a full system reconfigure.
#
#   print-git-sections [repo, changed, push_results]
#     Read-only. Called by ManifoldOS-Reshaping.nu to render the git
#     sections inside the main reshape summary. Does not stage, commit,
#     or push — only reads and displays.
#
#   fetch-commits-from [repo, n]
#     Returns the last N commits as a structured table with hash, date,
#     subject, author, and a one-line change summary from git show --stat.
#
#   fetch-status-from [repo]
#     Returns raw short-format git status lines for the working tree.
#
#   fetch-repo-stats-from [repo]
#     Returns a record with branch, remote URL, total commit count, last
#     push time, last tag, ahead/behind counts, and stash count.
#
# What happens on failure?
#
#   Every failure path clears the screen, renders a labelled error block
#   with the specific reason, and returns without touching git further.
#   The operator is never left with a partially committed or partially
#   pushed repository.
#
# Keybinding:
#
#   Ctrl+G in Nushell emacs mode runs the history pipeline standalone
#   from any prompt without triggering a reconfigure.
# =============================================================================


# =============================================================================
# CONFIGURATION
#
# Top-level record read by safety checks at runtime. Adjust thresholds here
# rather than hunting through individual check functions.
#
#   max_file_size_mb  — staged files larger than this trigger a hard abort
#   verbose_failures  — reserved for future per-check verbosity control
# =============================================================================

let config = {
    max_file_size_mb: 5
    verbose_failures: true
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
# a log. The log file is the record of what happened.
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
# These three functions are the read layer — they query the repository and
# return structured data. They never modify the index or working tree.
# Called both from the pipeline stages and from print-git-sections.
#
# fetch-commits-from
#   Parses `git log` with a pipe-delimited format so fields never collide
#   with commit message content. Adds a stat summary from `git show --stat`
#   so the history table shows what each commit actually touched.
#
# fetch-status-from
#   Returns raw short-format lines. Callers decide how to display them.
#   An empty list means a clean working tree.
#
# fetch-repo-stats-from
#   Aggregates the most useful single-glance metrics into one record.
#   ahead/behind use @{u} (the upstream tracking branch) — if no upstream
#   is configured, both default to 0 via the catch clause.
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
    git -C $repo status --short | lines | where { |l| $l | is-not-empty }
}

def fetch-repo-stats-from [repo: string] {
    {
        branch:      (git -C $repo branch --show-current | str trim)
        remote_url:  (try { git -C $repo remote get-url origin | str trim } catch { "none" })
        total:       (git -C $repo rev-list --count HEAD | str trim)
        last_push:   (git -C $repo log -1 --format="%ad" --date=relative | str trim)
        last_tag:    (try { git -C $repo describe --tags --abbrev=0 out+err> /dev/null | str trim } catch { "none" })
        ahead:       (try { git -C $repo rev-list --count @{u}..HEAD | str trim | into int } catch { 0 })
        behind:      (try { git -C $repo rev-list --count HEAD..@{u} | str trim | into int } catch { 0 })
        stash_count: (try { git -C $repo stash list | lines | length } catch { 0 })
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
#   Compares local HEAD against the upstream tracking ref. If the remote
#   has commits we don't have, pushing would either be rejected or create
#   a diverged history. Abort and show the missing commits so the operator
#   knows exactly what to pull.
#
# check-conflicts
#   Looks for files in the U (unmerged) diff-filter state. Any unresolved
#   conflict marker in a staged file would corrupt the commit. Hard abort.
#
# check-remote-reachable
#   Uses `git ls-remote` as a lightweight connectivity probe. Only runs if
#   a remote is configured. A failed probe aborts before staging so the
#   operator doesn't end up with staged changes and nowhere to push them.
#
# check-stash
#   Stashed changes are not a hard abort — they don't affect the index.
#   But they are a signal that the operator may have forgotten something.
#   Surfaces them with a prompt so the decision is explicit, not silent.
#
# check-large-files
#   Runs after `git add --all` so it sees exactly what is staged. Files
#   over the threshold are listed with their actual sizes. Hard abort —
#   large files in git history are permanent and expensive to remove.
#
# check-nothing-staged
#   Silent predicate. Returns true if the index is empty after staging.
#   Not an error — a reconfigure that touched no tracked files produces
#   a clean index. The caller renders the current state and exits cleanly.
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
    let behind_str = (try { git -C $repo rev-list --count HEAD..@{u} | str trim } catch { "0" })
    let behind     = (if ($behind_str | is-empty) { 0 } else { $behind_str | into int })
    if $behind > 0 {
        let commits = (git -C $repo log HEAD..@{u} --format="%h  %ad  %an  %s" --date=short | lines)
        render-error "BEHIND REMOTE" $"Your branch is ($behind) commit(s) behind. Pull before pushing." $commits
        true
    } else {
        false
    }
}

def check-conflicts [repo: string] {
    let conflicts = (git -C $repo diff --name-only --diff-filter=U | lines | where { |l| $l | is-not-empty })
    if ($conflicts | is-not-empty) {
        render-error "UNRESOLVED CONFLICTS" "Merge conflicts detected. Resolve them before pushing." (
            $conflicts | each { |f| { file: $f } }
        )
        true
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

def check-nothing-staged [repo: string] {
    let staged = (git -C $repo diff --cached --name-only | lines | where { |l| $l | is-not-empty })
    $staged | is-empty
}


# =============================================================================
# SECTION 4 — IMPACT
#
# Captures what the commit contains as structured data so the summary
# display can show exactly what changed without re-querying after the
# index has advanced.
#
# capture-changed
#   Runs three separate diff-filter queries (A/D/M) rather than one combined
#   query because numstat only covers modified files — added and deleted files
#   have no line counts to report, so they need their own pass.
#
# summarize-impact
#   Aggregates the changed list into counts by status. Used in the impact
#   header row before the per-file table.
#
# calculate-diff-stats
#   Totals lines added and deleted across all staged files from numstat.
#   Binary files and renames report "-" in numstat — into int will fail on
#   those, so the entire calculation is wrapped in try/catch.
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
#
# extract-generation-info
#   Reads the current Guix system generation number and creation date from
#   `guix system list-generations`. The first line of that command's output
#   describes the currently running generation. Used in the reshape summary
#   to confirm which generation the reconfigure produced.
#
#   Wrapped in try/catch because this is called in contexts where the running
#   system may not yet have a generation (fresh install) or the guix binary
#   may not be on PATH for the current user.
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
# All display logic lives here. The pipeline stages call these functions
# rather than printing directly so the display layer is fully separated
# from the operation layer.
#
# print-section
#   The universal display primitive. Every block of output in this file
#   and in ManifoldOS-Reshaping.nu goes through print-section. Consistent
#   label style, subtitle in grey, table body or a dash if empty.
#
# render-impact
#   Shows the commit's mutation signature: file counts by status in a
#   header row, then the full per-file diff table below it.
#
# render-position
#   Shows the repository's sync state relative to upstream: branch, remote,
#   tag, total commits, last push time, ahead/behind counts, stash warning
#   if stashes exist, working tree cleanliness, and line-level diff totals.
#
# render-history
#   Shows the last N commits as a table. Column widths are determined by
#   Nushell's table renderer automatically.
#
# render-nothing-to-commit
#   Called when the index is empty after staging. Not an error display —
#   renders the current repo position and history as a clean state summary.
#
# render-push-failure
#   Called when `git push` exits non-zero. Shows the raw stderr lines from
#   git so the operator sees the actual remote rejection message.
#
# print-git-sections
#   Public API called by ManifoldOS-Reshaping.nu to render git sections
#   inside the main reshape summary. Read-only — does not stage, commit,
#   or push. Takes the already-captured changed list so it reflects the
#   state at the time of the commit, not the current working tree.
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
    let state = if ($status | is-empty) { "✓ clean" } else { $"($status | length) change(s)" }
    $rows = ($rows | append { key: "State"      value: $state })
    $rows = ($rows | append { key: "Diff stats" value: $"+($diff_stats.added) lines  -($diff_stats.deleted) lines" })
    print-section "POSITION" "alignment between local drift and upstream state" $rows
}

def render-history [commits: list] {
    print-section "TEMPORAL TRACE" "compressed lineage of repository evolution" $commits
}

def render-nothing-to-commit [repo: string] {
    let stats      = (fetch-repo-stats-from $repo)
    let status     = (fetch-status-from $repo)
    let commits    = (fetch-commits-from $repo 10)
    let diff_stats = (calculate-diff-stats $repo)
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  Nothing new to commit — showing current state.(ansi reset)"
    print ""
    print-section "NOTHING TO COMMIT" "No staged changes detected" [{ status: "clean" }]
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
    let commits    = (fetch-commits-from $repo 10)
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
# ManifoldOS-Reshaping-History runs the full five-stage git pipeline.
#
# Entry points:
#   - Called by ManifoldOS-Reshaping.nu after a successful reconfigure,
#     with msg defaulting to "update"
#   - Called standalone via Ctrl+G for committing without reconfiguring
#
# The repo root is resolved dynamically from the current working directory
# via `git rev-parse --show-toplevel` rather than hardcoded so this function
# works correctly whether invoked from /ManifoldOS, a subdirectory, or via
# the keybinding from any prompt location.
#
# has_remote is resolved once at the top and threaded through all stages
# that need it. This avoids repeated subprocess calls and ensures consistent
# behaviour if the remote configuration changes mid-run (unlikely but safe).
# =============================================================================

def ManifoldOS-Reshaping-History [msg: string = "update"] {
    let repo = (try { git rev-parse --show-toplevel | str trim } catch {
        print $"(ansi red_bold)  ✗ Not a git repository(ansi reset)"
        return
    })

    let has_remote = (try { git -C $repo remote get-url origin | str trim } catch { "" } | is-not-empty)

    let steps = [
        { name: "Fetch" }
        { name: "Check" }
        { name: "Stage" }
        { name: "Commit" }
        { name: "Push" }
    ]
    mut timings = {}

    # --- Fetch ---
    rh-flow $steps "Fetch" $timings
    let t = (date now)
    try { git -C $repo fetch out+err> /dev/null } catch { }
    $timings = ($timings | insert Fetch $"(((date now) - $t) / 1sec | math round)s")

    # --- Safety checks — abort pipeline on first failure ---
    rh-flow $steps "Check" $timings
    let t = (date now)
    if (check-behind $repo)                           { return }
    if (check-conflicts $repo)                        { return }
    if $has_remote and (check-remote-reachable $repo) { return }
    if (check-stash $repo)                            { return }
    $timings = ($timings | insert Check $"(((date now) - $t) / 1sec | math round)s")

    # --- Stage — capture diff before index advances ---
    rh-flow $steps "Stage" $timings
    let t = (date now)
    git -C $repo add --all
    if (check-large-files $repo $config.max_file_size_mb) { return }
    let changed    = (capture-changed $repo)
    let diff_stats = (calculate-diff-stats $repo)
    $timings = ($timings | insert Stage $"(((date now) - $t) / 1sec | math round)s")

    # --- Commit ---
    rh-flow $steps "Commit" $timings
    let t = (date now)
    if (check-nothing-staged $repo) {
        render-nothing-to-commit $repo
        return
    }
    let commit_result = (git -C $repo commit -m $msg | complete)
    $timings = ($timings | insert Commit $"(((date now) - $t) / 1sec | math round)s")
    if $commit_result.exit_code != 0 {
        render-nothing-to-commit $repo
        return
    }

    # --- Push ---
    rh-flow $steps "Push" $timings
    let t = (date now)
    let push_result = if $has_remote {
        git -C $repo push | complete
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
    try { git -C $repo fetch out+err> /dev/null } catch { }

    let stats   = (fetch-repo-stats-from $repo)
    let status  = (fetch-status-from $repo)
    let commits = (fetch-commits-from $repo 10)

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
    print ""

    $changed
}


# =============================================================================
# SECTION 7 — KEYBINDING
#
# Ctrl+G in Nushell emacs mode runs the history pipeline standalone from
# any prompt. Useful for committing documentation, config, or module changes
# without triggering a full system reconfigure.
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