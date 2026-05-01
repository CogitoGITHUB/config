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
# CONFIGURATION
# =============================================================================

# Adjustable thresholds for safety checks
let config = {
    max_file_size_mb: 5
    check_secrets: true
    verbose_failures: true
    slow_output: true
    output_pause_ms: 1000
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
# =============================================================================

# Helper function to render errors consistently
def render-error [title: string, subtitle: string, details: any] {
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  Error encountered during workflow.(ansi reset)"
    print ""
    print-section $title $subtitle $details
    print ""
}

# Returns true (abort) if behind remote
def check-behind [repo: string] {
    let behind_str = (try { git -C $repo rev-list --count HEAD..@{u} | str trim } catch { "0" })
    let behind = (if ($behind_str | is-empty) { 0 } else { $behind_str | into int })
    if $behind > 0 {
        let commits = (git -C $repo log HEAD..@{u} --format="%h  %ad  %an  %s" --date=short | lines)
        render-error "BEHIND REMOTE" $"Your branch is ($behind) commit(s) behind. Pull before pushing." $commits
        true
    } else {
        false
    }
}

# Returns true (abort) if unresolved merge conflicts exist
def check-conflicts [repo: string] {
    let conflicts = (git -C $repo diff --name-only --diff-filter=U | lines | where { |l| $l | is-not-empty })
    if ($conflicts | is-not-empty) {
        let conflict_rows = ($conflicts | each { |f| { file: $f } })
        render-error "UNRESOLVED CONFLICTS" "Merge conflicts detected. Resolve them before pushing." $conflict_rows
        true
    } else {
        false
    }
}

# Returns true (abort) if any staged file exceeds threshold
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
        let large_rows = ($large | each { |f| 
            let full = ($repo | path join $f)
            let size_bytes = (ls $full | get 0.size | into int | into float)
            let size_mb = ($size_bytes / 1000000 | math round --precision 2)
            { file: $f  size_mb: $size_mb  limit_mb: $threshold_mb }
        })
        render-error "LARGE FILES STAGED" $"Files exceed ($threshold_mb)MB limit. Remove them before pushing." $large_rows
        true
    } else {
        false
    }
}

# Returns true (abort) if possible secrets detected in staged files
def check-secrets [repo: string] {
    let staged_files = (
        git -C $repo diff --cached --name-only 
        | lines 
        | where { |l| $l | is-not-empty }
    )
    
    # Patterns designed to match actual secrets in real files
    let patterns = [
        (["M" "I" "I" "E" "v" "Q" "I" "B" "A" "D" "A" "N" "B" "g"] | str join "")  # RSA private key
        (["M" "I" "I" "E" "p" "A" "I" "B" "A" "A" "K" "C" "A" "Q" "E" "A"] | str join "")  # RSA key format
        (["A" "A" "A" "A" "C" "3" "N" "z" "a" "C" "1" "[" "a" "-" "z" "0" "-" "9" "]"] | str join "")  # OpenSSH key
        (["s" "k" "_" "l" "i" "v" "e" "_" "[" "a" "-" "z" "A" "-" "Z" "0" "-" "9" "]" "{" "2" "0" "}"] | str join "")  # Stripe key
        (["A" "K" "I" "A" "[" "0" "-" "9" "A" "-" "Z" "]" "{" "1" "6" "}"] | str join "")  # AWS access key
        (["g" "h" "p" "_" "[" "A" "-" "Z" "a" "-" "z" "0" "-" "9" "_" "]" "{" "3" "6" "}"] | str join "")  # GitHub token
        (["---" "---" "BEGIN" " " "ENCRYPTED"] | str join "")  # Encrypted key marker
    ]
    
    mut hits = []
    for f in $staged_files {
        let full = ($repo | path join $f)
        if ($full | path exists) {
            for pattern in $patterns {
                let found = (try { 
                    open --raw $full | str contains $pattern 
                } catch { 
                    false 
                })
                if $found {
                    $hits = ($hits | append { file: $f  pattern: $pattern })
                }
            }
        }
    }
    if ($hits | is-not-empty) {
        render-error "POSSIBLE SECRETS DETECTED" "Credential patterns found. Review before pushing." $hits
        let choice = (["abort" "continue anyway — skip secrets check"] | input list --fuzzy "Secrets detected — proceed?")
        $choice == "abort"
    } else {
        false
    }
}

# Returns true (abort) if stashed changes exist — warns operator to review
def check-stash [repo: string] {
    let count = (try { git -C $repo stash list | lines | length } catch { 0 })
    if $count > 0 {
        let stashes = (git -C $repo stash list | lines)
        let subtitle = $"($count) stash\(es\) exist — they may conflict with the current push."
        render-error "STASHED CHANGES PRESENT" $subtitle $stashes
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Stash detected — proceed?")
        $choice == "abort"
    } else {
        false
    }
}

# Returns true (abort) if remote is unreachable
def check-remote-reachable [repo: string] {
    let result = (try { git -C $repo ls-remote --exit-code origin HEAD 2>@1 | complete } catch { { exit_code: 1, stderr: "unknown error" } })
    if $result.exit_code != 0 {
        render-error "REMOTE UNREACHABLE" "Cannot reach origin. Check your network connection." [{ status: "offline" }]
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

def calculate-diff-stats [repo: string] {
    try {
        let stats = (git -C $repo diff --cached --numstat | lines | where { |l| $l | is-not-empty })
        let total_added = (
            $stats 
            | each { |l| ($l | split row "\t" | get 0) | into int }
            | math sum
        )
        let total_deleted = (
            $stats 
            | each { |l| ($l | split row "\t" | get 1) | into int }
            | math sum
        )
        { added: $total_added  deleted: $total_deleted }
    } catch {
        { added: 0  deleted: 0 }
    }
}


# =============================================================================
# SECTION 4B — LOG ANALYSIS
# =============================================================================

def extract-warnings [log_content: string] {
    let warning_lines = (
        $log_content
        | lines
        | where { |l|
            (($l =~ "warning:" or $l =~ "deprecated:" or $l =~ "obsolete:") 
            and (not ($l =~ "ExternalCommand"))
            and (not ($l =~ "Span {")))
        }
    )
    $warning_lines
}

def extract-generation-info [repo: string] {
    try {
        let gen_output = (guix system list-generations | lines | first)
        let parts = ($gen_output | split row " " | where { |it| $it | is-not-empty })
        {
            generation: ($parts | get 1)
            date: (($parts | range 2..4 | str join " "))
        }
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
        { key: "Branch"  value: $stats.branch }
        { key: "Remote"  value: $stats.remote_url }
        { key: "Tag"     value: $stats.last_tag }
        { key: "Total commits"  value: $stats.total }
        { key: "Last push"  value: $stats.last_push }
        { key: "Sync"    value: $"+($stats.ahead) ahead  -($stats.behind) behind" }
    ]
    if $stats.stash_count > 0 {
        $rows = ($rows | append { key: "Stash"  value: $"($stats.stash_count) stashed change(s)" })
    }
    let state = if ($status | is-empty) { "✓ clean" } else { $"($status | length) change(s)" }
    $rows = ($rows | append { key: "State"  value: $state })
    $rows = ($rows | append { key: "Diff stats"  value: $"+($diff_stats.added) lines  -($diff_stats.deleted) lines" })
    print-section "POSITION" "alignment between local drift and upstream state" $rows
}

def render-history [commits: list] {
    print-section "TEMPORAL TRACE" "compressed lineage of repository evolution" $commits
}

def render-nothing-to-commit [repo: string] {
    let stats   = (fetch-repo-stats-from $repo)
    let status  = (fetch-status-from $repo)
    let commits = (fetch-commits-from $repo 10)
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
    let error_lines = ($stderr | lines | filter { |l| $l | is-not-empty })
    render-error "PUSH FAILED" "Remote rejected the push. Review errors and retry." $error_lines
}

# Public API — called by ManifoldOS-Reshaping.nu
def print-git-sections [repo: string, changed: list, push_results: list] {
    let stats   = (fetch-repo-stats-from $repo)
    let status  = (fetch-status-from $repo)
    let commits = (fetch-commits-from $repo 10)
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
# =============================================================================

def ManifoldOS-Reshaping-History [msg: string = "update"] {
    let repo = (try { git rev-parse --show-toplevel | str trim } catch {
        print $"(ansi red_bold)  ✗ Not a git repository(ansi reset)"
        return
    })

    # Only check for remote if we're actually going to push
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
    if $config.slow_output { sleep 1000ms }

    # --- Safety checks ---
    rh-flow $steps "Check" $timings
    let t = (date now)
    if (check-behind          $repo) { return }
    if (check-conflicts       $repo) { return }
    if $has_remote and (check-remote-reachable $repo) { return }
    if (check-stash           $repo) { return }
    $timings = ($timings | insert Check $"(((date now) - $t) / 1sec | math round)s")
    if $config.slow_output { sleep 1000ms }

    # --- Stage ---
    rh-flow $steps "Stage" $timings
    let t = (date now)
    git -C $repo add --all
    if (check-large-files $repo $config.max_file_size_mb) { return }
    if $config.check_secrets and (check-secrets $repo) { return }
    let changed = (capture-changed $repo)
    let diff_stats = (calculate-diff-stats $repo)
    $timings = ($timings | insert Stage $"(((date now) - $t) / 1sec | math round)s")
    if $config.slow_output { sleep 1000ms }

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
    if $config.slow_output { sleep 1000ms }

    # --- Push ---
    rh-flow $steps "Push" $timings
    let t = (date now)
    
    let push_result = if $has_remote {
        git -C $repo push | complete
    } else {
        # No remote configured - skip push, treat as success
        { exit_code: 0, stderr: "" }
    }
    
    $timings = ($timings | insert Push $"(((date now) - $t) / 1sec | math round)s")

    if $push_result.exit_code != 0 {
        render-push-failure $push_result.stderr
        return
    }

    rh-flow $steps "" $timings
    if $config.slow_output { sleep 1000ms }
    try { git -C $repo fetch out+err> /dev/null } catch { }

    let stats   = (fetch-repo-stats-from $repo)
    let status  = (fetch-status-from $repo)
    let commits = (fetch-commits-from $repo 10)

    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  Repository state after push.(ansi reset)"
    print ""
    
    # Show push status
    let push_status = if $has_remote {
        "✓ pushed to remote"
    } else {
        "✓ committed locally (no remote configured)"
    }
    print-section "PUSH STATUS" $push_status [{ status: $push_status }]
    
    render-impact $changed
    render-position $stats $status $diff_stats
    render-history $commits
    print ""
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