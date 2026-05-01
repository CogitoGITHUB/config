# =============================================================================
# ManifoldOS — Reshaping History
# =============================================================================
# Public API consumed by ManifoldOS-Reshaping.nu:
#   - print-git-sections [repo, changed, push_results]
#   - fetch-commits-from [repo, n]
#   - fetch-status-from  [repo]
#   - fetch-repo-stats-from [repo]
# =============================================================================


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
        last_tag:    (try { git -C $repo describe --tags --abbrev=0 | str trim } catch { "none" })
        ahead:       (try { git -C $repo rev-list --count @{u}..HEAD | str trim | into int } catch { 0 })
        behind:      (try { git -C $repo rev-list --count HEAD..@{u} | str trim | into int } catch { 0 })
        stash_count: (try { git -C $repo stash list | lines | length } catch { 0 })
    }
}


# =============================================================================
# SECTION 3 — SAFETY CHECKS
# =============================================================================

# Returns true (abort) if behind remote
def check-behind [repo: string] {
    let behind_str = (try { git -C $repo rev-list --count HEAD..@{u} | str trim } catch { "0" })
    let behind = (if ($behind_str | is-empty) { 0 } else { $behind_str | into int })
    if $behind > 0 {
        print -n "\e[2J\e[H"
        print ""
        print $"(ansi red_bold)  ⚠ BEHIND REMOTE(ansi reset)"
        print $"(ansi grey)  This machine is ($behind) commit(s) behind. Pull before pushing.(ansi reset)"
        print ""
        git -C $repo log HEAD..@{u} --format="%h  %ad  %an  %s" --date=short
        | lines
        | each { |l| print $"  ($l)" }
        print ""
        true
    } else {
        false
    }
}

# Returns true (abort) if unresolved merge conflicts exist
def check-conflicts [repo: string] {
    let conflicts = (git -C $repo diff --name-only --diff-filter=U | lines | where { |l| $l | is-not-empty })
    if ($conflicts | is-not-empty) {
        print -n "\e[2J\e[H"
        print ""
        print $"(ansi red_bold)  ⚠ UNRESOLVED CONFLICTS(ansi reset)"
        print $"(ansi grey)  Resolve these before pushing.(ansi reset)"
        print ""
        for f in $conflicts { print $"  ✗  ($f)" }
        print ""
        true
    } else {
        false
    }
}

# Returns true (abort) if any staged file exceeds 5MB
def check-large-files [repo: string] {
    let threshold = 5000000  # 5MB
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
        print ""
        print $"(ansi red_bold)  ⚠ LARGE FILES STAGED(ansi reset)"
        print $"(ansi grey)  These files exceed 5MB — refusing to push.(ansi reset)"
        print ""
        for f in $large { print $"  ⚠  ($f)" }
        print ""
        true
    } else {
        false
    }
}

# # Returns true (abort) if possible secrets detected in staged files
# def check-secrets [repo: string] {
#     let patterns = ["PRIVATE KEY" "BEGIN RSA" "password=" "secret=" "token=" "api_key=" "AWS_SECRET"]
#     let staged_files = (git -C $repo diff --cached --name-only | lines | where { |l| $l | is-not-empty })
#     mut hits = []
#     for f in $staged_files {
#         let full = ($repo | path join $f)
#         if ($full | path exists) {
#             for pattern in $patterns {
#                 let found = (try { open $full | str contains $pattern } catch { false })
#                 if $found {
#                     $hits = ($hits | append { file: $f  pattern: $pattern })
#                 }
#             }
#         }
#     }
#     if ($hits | is-not-empty) {
#         print ""
#         print $"(ansi red_bold)  ⚠ POSSIBLE SECRETS DETECTED(ansi reset)"
#         print $"(ansi grey)  Review these files before pushing.(ansi reset)"
#         print ""
#         $hits | print
#         print ""
#         true
#     } else {
#         false
#     }
# }

# Returns true (abort) if stashed changes exist — warns operator to review
def check-stash [repo: string] {
    let count = (try { git -C $repo stash list | lines | length } catch { 0 })
    if $count > 0 {
        print ""
        print $"(ansi red_bold)  ⚠ STASHED CHANGES PRESENT(ansi reset)"
        print $"(ansi grey)  ($count) stash(es) exist — they may conflict with the current push.(ansi reset)"
        print ""
        git -C $repo stash list | lines | each { |l| print $"  ($l)" }
        print ""
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Stash detected — proceed?")
        $choice == "abort"
    } else {
        false
    }
}

# Returns true (abort) if remote is unreachable
def check-remote-reachable [repo: string] {
    let result = (try { git -C $repo ls-remote --exit-code origin HEAD | complete } catch { { exit_code: 1 } })
    if $result.exit_code != 0 {
        print ""
        print $"(ansi red_bold)  ⚠ REMOTE UNREACHABLE(ansi reset)"
        print $"(ansi grey)  Cannot reach origin — skipping push.(ansi reset)"
        print ""
        true
    } else {
        false
    }
}

# Returns true (abort) if no remote is configured
def check-remote-exists [repo: string] {
    let remote = (try { git -C $repo remote get-url origin | str trim } catch { "" })
    if ($remote | is-empty) {
        print ""
        print $"(ansi red_bold)  ⚠ NO REMOTE CONFIGURED(ansi reset)"
        print $"(ansi grey)  No origin remote found — commit will be local only.(ansi reset)"
        print ""
        true
    } else {
        false
    }
}

# Returns true (abort) if nothing is staged to commit
def check-nothing-staged [repo: string] {
    let staged = (git -C $repo diff --cached --name-only | lines | where { |l| $l | is-not-empty })
    if ($staged | is-empty) {
        true
    } else {
        false
    }
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

def render-position [stats: record, status: list] {
    mut rows = [
        { key: "Branch"  value: $stats.branch }
        { key: "Remote"  value: $stats.remote_url }
        { key: "Tag"     value: $stats.last_tag }
        { key: "Total"   value: $stats.total }
        { key: "Pushed"  value: $stats.last_push }
        { key: "Sync"    value: $"+($stats.ahead) ahead  -($stats.behind) behind" }
    ]
    if $stats.stash_count > 0 {
        $rows = ($rows | append { key: "Stash"  value: $"($stats.stash_count) stashed change(s)" })
    }
    let state = if ($status | is-empty) { "✓ clean" } else { $"($status | length) change(s)" }
    $rows = ($rows | append { key: "State"  value: $state })
    print-section "POSITION" "alignment between local drift and upstream state" $rows
}

def render-history [commits: list] {
    print-section "TEMPORAL TRACE" "compressed lineage of repository evolution" $commits
}

def render-file-delta [changed: list] {
    print-section "FILE DELTA" "what has just been altered in the system state" (
        if ($changed | is-empty) {
            [{ state: "no changes" }]
        } else {
            $changed
        }
    )
}

def render-nothing-to-commit [repo: string] {
    let stats   = (fetch-repo-stats-from $repo)
    let status  = (fetch-status-from $repo)
    let commits = (fetch-commits-from $repo 10)
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  Nothing new to commit — showing current state.(ansi reset)"
    print ""
    render-position $stats $status
    render-history $commits
}

def render-push-failure [stderr: string] {
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)  ✗ PUSH FAILED(ansi reset)"
    print $"(ansi grey)  Remote rejected the push. Resolve and retry.(ansi reset)"
    print ""
    print $stderr
    print ""
}

# Public API — called by ManifoldOS-Reshaping.nu
def print-git-sections [repo: string, changed: list, push_results: list] {
    let stats   = (fetch-repo-stats-from $repo)
    let status  = (fetch-status-from $repo)
    let commits = (fetch-commits-from $repo 10)

    if ($push_results | is-not-empty) {
        print-section "PUSH" "steps completed in this operation" (
            $push_results | each { |r| { step: $r.description } }
        )
    }

    if ($changed | is-not-empty) {
        render-impact $changed
    }

    render-history $commits
    render-position $stats $status
}


# =============================================================================
# SECTION 6 — MAIN
# =============================================================================

def ManifoldOS-Reshaping-History [msg: string = "update"] {
    let repo = (try { git rev-parse --show-toplevel | str trim } catch {
        print $"(ansi red_bold)  ✗ Not a git repository(ansi reset)"
        return
    })

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

    # --- Safety checks ---
    rh-flow $steps "Check" $timings
    let t = (date now)
    if (check-behind          $repo) { return }
    if (check-conflicts       $repo) { return }
    if (check-remote-exists   $repo) { return }
    if (check-remote-reachable $repo) { return }
    if (check-stash           $repo) { return }
    $timings = ($timings | insert Check $"(((date now) - $t) / 1sec | math round)s")

    # --- Stage ---
    rh-flow $steps "Stage" $timings
    let t = (date now)
    git -C $repo add --all
    if (check-large-files $repo) { return }
#    if (check-secrets     $repo) { return }
    let changed = (capture-changed $repo)
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
    let push_result = (git -C $repo push | complete)
    $timings = ($timings | insert Push $"(((date now) - $t) / 1sec | math round)s")

    if $push_result.exit_code != 0 {
        render-push-failure $push_result.stderr
        return
    }

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
    render-impact $changed
    render-position $stats $status
    render-history $commits
    print ""
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