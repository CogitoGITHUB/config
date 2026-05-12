# =============================================================================
# ManifoldOS — Reshaping History
# =============================================================================
let config = {
    max_file_size_mb: 5
    verbose_failures: true
    commits_to_show:  10
    op_log_to_show:   5
}
# =============================================================================
# SECTION 0 — REPO DETECTION + JJ INIT
# =============================================================================
def find-repo-root [] {
    mut dir = (pwd)
    loop {
        if ($dir | path join ".git" | path exists) or ($dir | path join ".jj" | path exists) {
            return $dir
        }
        let parent = ($dir | path dirname)
        if $parent == $dir { return null }
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
# SECTION 2 — DATA COLLECTION
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
            let p = ($line | split row "|")
            { change_id: "git"  commit_id: ($p | get 0)  age: ($p | get 1)  subject: ($p | get 2)  author: ($p | get 3) }
        }
    }
}
def fetch-status-from [repo: string] {
    try {
        jj --repository $repo status | lines | where { |l| $l | is-not-empty }
    } catch {
        git -C $repo status --short | lines | where { |l| $l | is-not-empty }
    }
}
# Resolve current branch: prefer git branch name, fall back to jj bookmark, then "—"
def resolve-branch [repo: string] {
    let git_branch = (try { git -C $repo branch --show-current | str trim } catch { "" })
    if ($git_branch | is-not-empty) { return $git_branch }
    let jj_bookmark = (try { jj --repository $repo log --no-graph -r @ --template 'bookmarks' | str trim } catch { "" })
    if ($jj_bookmark | is-not-empty) { return $jj_bookmark }
    "—"
}
def fetch-repo-stats-from [repo: string, --json] {
    let branch = (resolve-branch $repo)
    # ahead/behind against the tracking remote branch for the current git branch
    let ahead = (try {
        git -C $repo rev-list --count $"@{u}..HEAD" | str trim | into int
    } catch { null })
    let behind = (try {
        git -C $repo rev-list --count $"HEAD..@{u}" | str trim | into int
    } catch { null })
    let stats = {
        branch:      $branch
        remote_url:  (try { git -C $repo remote get-url origin | str trim } catch { "none" })
        total:       (try { git -C $repo rev-list --count HEAD | str trim } catch { "?" })
        last_push:   (try { git -C $repo log -1 --format="%ad" --date=relative | str trim } catch { "?" })
        last_tag:    (try { git -C $repo describe --tags --abbrev=0 out+err>/dev/null | str trim } catch { "none" })
        ahead:       (if $ahead  == null { "?" } else { $ahead  | into string })
        behind:      (if $behind == null { "?" } else { $behind | into string })
        stash_count: (try { git -C $repo stash list | lines | length } catch { 0 })
    }
    if $json { $stats | to json } else { $stats }
}
# Parse jj op log into a table: one row per operation
def fetch-op-log-from [repo: string, n: int] {
    try {
        let tmpl = 'id.short(12) ++ "|" ++ description ++ "|" ++ user ++ "|" ++ time.start().ago() ++ "\n"'
        jj --repository $repo op log --no-graph --limit $n --template $tmpl
        | lines
        | where { |l| $l | is-not-empty }
        | each { |line|
            let p = ($line | split row "|")
            {
                op:          ($p | get 0)
                description: ($p | get 1)
                user:        ($p | get 2)
                when:        ($p | get 3)
            }
        }
    } catch {
        # fallback: raw lines wrapped in a single-column table
        try {
            jj --repository $repo op log --no-graph --limit $n
            | lines
            | where { |l| $l | is-not-empty }
            | each { |line| { op: "—"  description: $line  user: ""  when: "" } }
        } catch {
            [{ op: "—"  description: "(op log unavailable)"  user: ""  when: "" }]
        }
    }
}
def snapshot-op-id [repo: string] {
    try {
        jj --repository $repo op log --no-graph --limit 1 --template 'id.short(12)' | str trim
    } catch { null }
}
# =============================================================================
# SECTION 3 — SAFETY CHECKS
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
        git -C $repo rev-list --count $"HEAD..@{u}" | str trim | into int
    } catch { 0 })
    if $behind > 0 {
        let commits = (git -C $repo log HEAD..@{u} --format="%h  %ad  %an  %s" --date=short | lines)
        render-error "BEHIND REMOTE" $"Branch is ($behind) commit\(s\) behind. Pull before pushing." $commits
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
        render-error "UNRESOLVED CONFLICTS" "Resolve before committing." [
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
        render-error "REMOTE UNREACHABLE" "Cannot reach origin. Check your network." [{ status: "offline" }]
        true
    } else {
        false
    }
}
def check-stash [repo: string] {
    let count = (try { git -C $repo stash list | lines | length } catch { 0 })
    if $count > 0 {
        let stashes = (git -C $repo stash list | lines)
        render-error "STASHED CHANGES" $"($count) stash\(es\) may conflict with this push." $stashes
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Stash detected — proceed?")
        $choice == "abort"
    } else {
        false
    }
}
# =============================================================================
# SECTION 4 — IMPACT
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
            { status: $status  file: ($parts | get 1) }
        }
    } catch { [] }
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
        let stats   = (jj --repository $repo diff --stat | lines | last | str trim)
        let added   = (try { $stats | parse --regex '(\d+) insertion' | get capture0.0 | into int } catch { 0 })
        let deleted = (try { $stats | parse --regex '(\d+) deletion'  | get capture0.0 | into int } catch { 0 })
        { added: $added  deleted: $deleted }
    } catch { { added: 0  deleted: 0 } }
}
# =============================================================================
# SECTION 4B — SYSTEM INFO
# =============================================================================
def extract-generation-info [] {
    try {
        let gen_output = (guix system list-generations | lines | first)
        let parts      = ($gen_output | split row " " | where { |it| $it | is-not-empty })
        { generation: ($parts | get 1)  date: ($parts | range 2..4 | str join " ") }
    } catch { { generation: "unknown"  date: "unknown" } }
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
    print-section "IMPACT" $"($impact.files) file\(s\) — ($impact.added) added  ($impact.deleted) deleted  ($impact.modified) modified" $changed
}
def render-position [stats: record, status: list, diff_stats: record] {
    mut rows = [
        { key: "branch"  value: $stats.branch }
        { key: "remote"  value: $stats.remote_url }
        { key: "commits" value: $stats.total }
        { key: "pushed"  value: $stats.last_push }
        { key: "sync"    value: $"↑($stats.ahead) ↓($stats.behind)" }
        { key: "diff"    value: $"+($diff_stats.added) / -($diff_stats.deleted) lines" }
    ]
    if ($stats.last_tag != "none") {
        $rows = ($rows | append { key: "tag"  value: $stats.last_tag })
    }
    if $stats.stash_count > 0 {
        $rows = ($rows | append { key: "stash"  value: $"($stats.stash_count) stashed" })
    }
    let state = if ($status | is-empty) { "clean" } else { $"($status | length) change\(s\)" }
    $rows = ($rows | append { key: "tree"  value: $state })
    print-section "POSITION" "repository sync state" $rows
}
def render-history [commits: list] {
    print-section "HISTORY" "recent commits" $commits
}
def render-op-log [repo: string, pre_op_id: string] {
    let ops = (fetch-op-log-from $repo $config.op_log_to_show)
    print-section "OPERATIONS" "jj undo stack — most recent first" $ops
    if ($pre_op_id | is-not-empty) {
        print $"  (ansi grey)undo target  ($pre_op_id)  →  jj op restore ($pre_op_id)(ansi reset)"
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
    print $"(ansi grey)  Nothing new to commit — current state.(ansi reset)"
    print ""
    render-position $stats $status $diff_stats
    render-history $commits
}
def render-push-failure [stderr: string] {
    render-error "PUSH FAILED" "Remote rejected the push." ($stderr | lines | where { |l| $l | is-not-empty })
}
def print-git-sections [repo: string, changed: list, push_results: list] {
    let stats      = (fetch-repo-stats-from $repo)
    let status     = (fetch-status-from $repo)
    let commits    = (fetch-commits-from $repo $config.commits_to_show)
    let diff_stats = (calculate-diff-stats $repo)
    if ($push_results | is-not-empty) {
        print-section "PUSH" "steps completed" ($push_results | each { |r| { step: $r.description } })
    }
    if ($changed | is-not-empty) { render-impact $changed }
    render-history $commits
    render-position $stats $status $diff_stats
}
# =============================================================================
# SECTION 6 — MAIN
# =============================================================================
def has-dirty-working-copy [repo: string] {
    try { (jj --repository $repo diff --stat | str trim | is-not-empty) } catch { false }
}
def ManifoldOS-Reshaping-History [msg: string = "update"] {
    let repo = (find-repo-root)
    if $repo == null {
        print -e $"(ansi red_bold)  ✗ no git or jj repo found(ansi reset)"
        return
    }
    let init_ok = (ensure-jj-initialized $repo)
    if not $init_ok { return }
    let has_remote = (try { git -C $repo remote | str trim | is-not-empty } catch { false })
    if not $has_remote {
        print -e $"(ansi red_bold)  ✗ no remote configured — git remote add origin <url>(ansi reset)"
        return
    }
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
        print $"(ansi yellow)  ⚠ working copy dirty — fetch may fold remote changes in(ansi reset)"
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
    let branch = (resolve-branch $repo)
    let commit_msg = if ($msg == "update") {
        let ts = (date now | format date "%Y-%m-%d %H:%M")
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
    let stats      = (fetch-repo-stats-from $repo)
    let status     = (fetch-status-from $repo)
    let commits    = (fetch-commits-from $repo $config.commits_to_show)
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  pushed  ($branch)  (date now | format date '%Y-%m-%d %H:%M')(ansi reset)"
    print ""
    render-impact $changed
    render-position $stats $status $diff_stats
    render-history $commits
    render-op-log $repo $pre_op_id
    print ""
}
# =============================================================================
# SECTION 7 — CONVENIENCE COMMANDS
# =============================================================================
def jj-undo [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let result = (do { jj --repository $repo op undo } | complete)
    if $result.exit_code != 0 {
        print -e $"(ansi red_bold)  ✗ undo failed:(ansi reset) ($result.stderr)"
    } else {
        print $"(ansi green)  ✓ undone(ansi reset)"
        fetch-op-log-from $repo 3 | print
    }
}
def jj-restore-op [op_id: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let result = (do { jj --repository $repo op restore $op_id } | complete)
    if $result.exit_code != 0 {
        print -e $"(ansi red_bold)  ✗ restore failed:(ansi reset) ($result.stderr)"
    } else {
        print $"(ansi green)  ✓ restored to ($op_id)(ansi reset)"
    }
}
def jj-split  [] { let repo = (find-repo-root); if $repo == null { return }; jj --repository $repo split }
def jj-squash [] { let repo = (find-repo-root); if $repo == null { return }; jj --repository $repo squash }
def jj-evolog [] { let repo = (find-repo-root); if $repo == null { return }; jj --repository $repo evolog }
def jj-stats-json [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    fetch-repo-stats-from $repo --json
}
# =============================================================================
# SECTION 8 — KEYBINDINGS
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