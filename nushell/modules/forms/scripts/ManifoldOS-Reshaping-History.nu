# =============================================================================
# ManifoldOS — Reshaping History
# =============================================================================
let config = {
    max_file_size_mb: 5
    verbose_failures: true
    commits_to_show:  10
    op_log_to_show:   5
    author_name:      "CogitoGITHUB"
    author_email:     "vlasceanupaulinoionut@gmail.com"
    default_branch:   "master"
}
# =============================================================================
# SECTION 0 — REPO DETECTION + BOOTSTRAP
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

# Full bootstrap: git init → set identity → jj colocate → add remote → initial commit → push
def bootstrap-repo [remote_url: string] {
    let repo = (pwd)
    print $"(ansi red_bold)  ⚙ bootstrapping ($repo)(ansi reset)"

    # git init
    let gi = (do { git init $repo } | complete)
    if $gi.exit_code != 0 { print -e $"(ansi red_bold)  ✗ git init failed:(ansi reset) ($gi.stderr)"; return false }
    print $"(ansi green)  ✓ git init(ansi reset)"

    # set git identity
    git -C $repo config user.name  $config.author_name
    git -C $repo config user.email $config.author_email
    print $"(ansi green)  ✓ identity set ($config.author_name) <($config.author_email)>(ansi reset)"

    # add remote
    let ra = (do { git -C $repo remote add origin $remote_url } | complete)
    if $ra.exit_code != 0 { print -e $"(ansi red_bold)  ✗ remote add failed:(ansi reset) ($ra.stderr)"; return false }
    print $"(ansi green)  ✓ remote → ($remote_url)(ansi reset)"

    # jj colocate
    let ji = (do { jj git init --colocate $repo } | complete)
    if $ji.exit_code != 0 { print -e $"(ansi red_bold)  ✗ jj init failed:(ansi reset) ($ji.stderr)"; return false }
    print $"(ansi green)  ✓ jj colocated(ansi reset)"

    # jj identity
    jj config set --user user.name  $config.author_name
    jj config set --user user.email $config.author_email

    # create bookmark
    let bm = $config.default_branch
    let bmc = (do { jj --repository $repo bookmark create $bm } | complete)
    if $bmc.exit_code != 0 { print $"(ansi yellow)  ⚠ bookmark create: ($bmc.stderr)(ansi reset)" }
    else { print $"(ansi green)  ✓ bookmark ($bm) created(ansi reset)" }

    # initial commit
    let ts = (date now | format date "%Y-%m-%d %H:%M")
    let author_flag = $"($config.author_name) <($config.author_email)>"
    let dc = (do { jj --repository $repo metaedit -m $"[($bm)] init ($ts)" --author $author_flag } | complete)
    if $dc.exit_code != 0 { print $"(ansi yellow)  ⚠ metaedit: ($dc.stderr)(ansi reset)" }

    # advance bookmark to @
    jj --repository $repo bookmark set $bm -r '@' | ignore

    # try to push
    let pr = (do { jj --repository $repo git push --bookmark $bm } | complete)
    if $pr.exit_code != 0 {
        # try tracking first
        jj --repository $repo bookmark track $bm --remote=origin | ignore
        let pr2 = (do { jj --repository $repo git push --bookmark $bm } | complete)
        if $pr2.exit_code != 0 {
            print -e $"(ansi red_bold)  ✗ push failed:(ansi reset) ($pr2.stderr)"
            return false
        }
    }
    print $"(ansi green)  ✓ pushed → ($remote_url) on ($bm)(ansi reset)"
    true
}

# Ensure jj is colocated and identity is always set.
def ensure-jj-initialized [repo: string] {
    let jj_dir = ($repo | path join ".jj")
    if not ($jj_dir | path exists) {
        print $"(ansi yellow)  jj not initialized — running jj git init --colocate(ansi reset)"
        let result = (do { jj git init --colocate $repo } | complete)
        if $result.exit_code != 0 {
            print -e $"(ansi red_bold)  ✗ jj init failed:(ansi reset) ($result.stderr)"
            return false
        }
        print $"(ansi green)  ✓ jj initialized \(colocated\)(ansi reset)"
    }
    # Always enforce identity — never rely on ambient config
    jj config set --user user.name  $config.author_name
    jj config set --user user.email $config.author_email
    git -C $repo config user.name  $config.author_name
    git -C $repo config user.email $config.author_email
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
def list-bookmarks [repo: string] {
    try {
        jj --repository $repo bookmark list
        | lines
        | where { |l| $l | is-not-empty }
        | each { |l| $l | split row ":" | get 0 | str trim }
    } catch { [] }
}

def resolve-bookmark [repo: string] {
    let known = (list-bookmarks $repo)
    if ($known | is-empty) { return null }
    let on_parent = (try {
        jj --repository $repo log --no-graph -r '@-' --template 'bookmarks.join("\n")' | lines | where { |l| $l | is-not-empty } | get 0
    } catch { "" })
    if ($on_parent | is-not-empty) and ($known | any { |b| $b == $on_parent }) { return $on_parent }
    let on_wc = (try {
        jj --repository $repo log --no-graph -r '@' --template 'bookmarks.join("\n")' | lines | where { |l| $l | is-not-empty } | get 0
    } catch { "" })
    if ($on_wc | is-not-empty) and ($known | any { |b| $b == $on_wc }) { return $on_wc }
    $known | get 0
}

def resolve-ahead-behind [repo: string, bookmark: string] {
    let ahead = (try {
        jj --repository $repo log --no-graph -r $"remote_bookmarks\(exact:\"($bookmark)\"\)..($bookmark)" --limit 100
        | lines | where { |l| $l | is-not-empty } | length | into string
    } catch { "?" })
    let behind = (try {
        jj --repository $repo log --no-graph -r $"($bookmark)..remote_bookmarks\(exact:\"($bookmark)\"\)" --limit 100
        | lines | where { |l| $l | is-not-empty } | length | into string
    } catch { "?" })
    { ahead: $ahead  behind: $behind }
}

def fetch-commits-from [repo: string, n: int] {
    let tmpl = 'change_id.short(8) ++ "|" ++ commit_id.short(8) ++ "|" ++ author.timestamp().ago() ++ "|" ++ description.first_line() ++ "|" ++ author.name() ++ "\n"'
    try {
        jj --repository $repo log --no-graph --limit $n --template $tmpl
        | lines | where { |l| $l | is-not-empty }
        | each { |line|
            let p = ($line | split row "|")
            { change: ($p | get 0)  commit: ($p | get 1)  age: ($p | get 2)  subject: ($p | get 3)  author: ($p | get 4) }
        }
    } catch {
        git -C $repo log --format="%h|%ad|%s|%an" --date=relative $"-($n)"
        | lines | where { |l| $l | is-not-empty }
        | each { |line|
            let p = ($line | split row "|")
            { change: "—"  commit: ($p | get 0)  age: ($p | get 1)  subject: ($p | get 2)  author: ($p | get 3) }
        }
    }
}

def fetch-status-from [repo: string] {
    try { jj --repository $repo status | lines | where { |l| $l | is-not-empty } } catch { [] }
}

def fetch-repo-stats-from [repo: string, bookmark: string, --json] {
    let sync = if ($bookmark | is-not-empty) { resolve-ahead-behind $repo $bookmark } else { { ahead: "?"  behind: "?" } }
    let stats = {
        bookmark:    (if ($bookmark | is-empty) { "none" } else { $bookmark })
        remote_url:  (try { git -C $repo remote get-url origin | str trim } catch { "none" })
        total:       (try { git -C $repo rev-list --count HEAD | str trim } catch { "?" })
        last_push:   (try { git -C $repo log -1 --format="%ad" --date=relative | str trim } catch { "?" })
        last_tag:    (try { do { git -C $repo describe --tags --abbrev=0 } | complete | if $in.exit_code == 0 { $in.stdout | str trim } else { "" } } catch { "" })
        ahead:       $sync.ahead
        behind:      $sync.behind
        stash_count: (try { git -C $repo stash list | lines | length } catch { 0 })
    }
    if $json { $stats | to json } else { $stats }
}

def fetch-op-log-from [repo: string, n: int] {
    try {
        let tmpl = 'id.short(12) ++ "|" ++ description ++ "|" ++ user ++ "|" ++ time.start().ago() ++ "\n"'
        jj --repository $repo op log --no-graph --limit $n --template $tmpl
        | lines | where { |l| $l | is-not-empty }
        | each { |line|
            let p = ($line | split row "|")
            { op: ($p | get 0)  description: ($p | get 1)  user: ($p | get 2)  when: ($p | get 3) }
        }
    } catch { [{ op: "—"  description: "(op log unavailable)"  user: ""  when: "" }] }
}

def snapshot-op-id [repo: string] {
    try { jj --repository $repo op log --no-graph --limit 1 --template 'id.short(12)' | str trim } catch { null }
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

def check-behind [repo: string, bookmark: string] {
    if ($bookmark | is-empty) { return false }
    let behind = (try {
        jj --repository $repo log --no-graph -r $"($bookmark)..remote_bookmarks\(exact:\"($bookmark)\"\)" --limit 100
        | lines | where { |l| $l | is-not-empty } | length
    } catch { 0 })
    if $behind > 0 {
        let commits = (try {
            jj --repository $repo log --no-graph -r $"($bookmark)..remote_bookmarks\(exact:\"($bookmark)\"\)" --limit 20
            | lines | where { |l| $l | is-not-empty }
        } catch { [] })
        render-error "BEHIND REMOTE" $"Bookmark ($bookmark) is ($behind) commit\(s\) behind. Pull before pushing." $commits
        true
    } else { false }
}

def check-conflicts [repo: string] {
    let has_conflicts = (try { jj --repository $repo log --no-graph -r 'conflicts()' | str trim | is-not-empty } catch { false })
    if $has_conflicts {
        render-error "UNRESOLVED CONFLICTS" "Resolve before committing." [
            { hint: "jj resolve — interactive resolver" }
            { hint: "jj diff    — inspect conflicts"    }
        ]
        true
    } else { false }
}

def check-remote-reachable [repo: string] {
    let result = (try { git -C $repo ls-remote --exit-code origin HEAD | complete } catch { { exit_code: 1 } })
    if $result.exit_code != 0 {
        render-error "REMOTE UNREACHABLE" "Cannot reach origin. Check your network." [{ status: "offline" }]
        true
    } else { false }
}

def check-stash [repo: string] {
    let count = (try { git -C $repo stash list | lines | length } catch { 0 })
    if $count > 0 {
        let stashes = (git -C $repo stash list | lines)
        render-error "STASHED CHANGES" $"($count) stash\(es\) may conflict with this push." $stashes
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Stash detected — proceed?")
        $choice == "abort"
    } else { false }
}
# =============================================================================
# SECTION 4 — IMPACT
# =============================================================================
def capture-changed [repo: string] {
    try {
        jj --repository $repo diff --summary
        | lines | where { |l| $l | is-not-empty }
        | each { |line|
            let parts  = ($line | str trim | split row " " | where { |p| $p | is-not-empty })
            let status = match ($parts | get 0) { "A" => "added"  "D" => "deleted"  "M" => "modified"  _ => "changed" }
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
# SECTION 5 — RENDERING
# =============================================================================
def print-section [label: string, subtitle: string, rows: any] {
    print ""
    print $"(ansi red_bold)  ($label)(ansi reset)"
    print $"(ansi grey)  ($subtitle)(ansi reset)"
    if ($rows | is-empty) { print $"(ansi grey)  —(ansi reset)" } else { $rows | print }
}

def render-impact [changed: list] {
    let impact = (summarize-impact $changed)
    print-section "IMPACT" $"($impact.files) file\(s\) — ($impact.added) added  ($impact.deleted) deleted  ($impact.modified) modified" $changed
}

def render-position [stats: record, status: list, diff_stats: record] {
    mut rows = [
        { key: "bookmark" value: $stats.bookmark }
        { key: "remote"   value: $stats.remote_url }
        { key: "commits"  value: $stats.total }
        { key: "pushed"   value: $stats.last_push }
        { key: "sync"     value: $"↑($stats.ahead) ↓($stats.behind)" }
        { key: "diff"     value: $"+($diff_stats.added) / -($diff_stats.deleted) lines" }
    ]
    if ($stats.last_tag | is-not-empty) { $rows = ($rows | append { key: "tag"   value: $stats.last_tag }) }
    if $stats.stash_count > 0          { $rows = ($rows | append { key: "stash" value: $"($stats.stash_count) stashed" }) }
    let state = if ($status | is-empty) { "clean" } else { $"($status | length) change\(s\)" }
    $rows = ($rows | append { key: "tree" value: $state })
    print-section "POSITION" "repository sync state" $rows
}

def render-history [commits: list] { print-section "HISTORY" "recent commits" $commits }

def render-op-log [repo: string, pre_op_id: string] {
    let ops = (fetch-op-log-from $repo $config.op_log_to_show)
    print-section "OPERATIONS" "jj undo stack — most recent first" $ops
    if ($pre_op_id | is-not-empty) {
        print $"  (ansi grey)undo target  ($pre_op_id)  →  jj op restore ($pre_op_id)(ansi reset)"
    }
}

def render-checklist [checklist: list] { print-section "PIPELINE" "stage-by-stage result" $checklist }

def render-push-failure [stderr: string] {
    render-error "PUSH FAILED" "Remote rejected the push." ($stderr | lines | where { |l| $l | is-not-empty })
}
# =============================================================================
# SECTION 6 — PUSH HELPER (shared by main + bootstrap)
# =============================================================================
def do-push [repo: string, bm: string] {
    let r = (do { jj --repository $repo git push --bookmark $bm } | complete)
    if $r.exit_code != 0 and ($r.stderr | str contains "Non-tracking remote bookmark") {
        jj --repository $repo bookmark track $bm --remote=origin | ignore
        do { jj --repository $repo git push --bookmark $bm } | complete
    } else { $r }
}
# =============================================================================
# SECTION 7 — MAIN
# =============================================================================
def has-dirty-working-copy [repo: string] {
    try { (jj --repository $repo diff --stat | str trim | is-not-empty) } catch { false }
}

def ManifoldOS-Reshaping-History [msg: string = "update"] {
    # ── NO REPO: offer to bootstrap ─────────────────────────────────────────
    let repo = (find-repo-root)
    if $repo == null {
        print -n "\e[2J\e[H"
        print ""
        print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
        print $"(ansi grey)  No git/jj repo found in ($env.PWD) or any parent.(ansi reset)"
        print ""
        let choice = (["bootstrap repo here" "abort"] | input list --fuzzy "What do you want to do?")
        if $choice == "abort" { return }
        let remote_url = (input "  Remote URL (e.g. git@github.com:user/repo.git): " | str trim)
        if ($remote_url | is-empty) { print -e "  ✗ no URL provided"; return }
        let ok = (bootstrap-repo $remote_url)
        if not $ok { return }
        # re-run the full flow now that repo exists
        ManifoldOS-Reshaping-History $msg
        return
    }

    let init_ok = (ensure-jj-initialized $repo)
    if not $init_ok { return }

    # ── NO REMOTE: offer to add one ─────────────────────────────────────────
    let has_remote = (try { git -C $repo remote | str trim | is-not-empty } catch { false })
    if not $has_remote {
        print $"(ansi yellow)  ⚠ no remote configured(ansi reset)"
        let remote_url = (input "  Remote URL (e.g. git@github.com:user/repo.git): " | str trim)
        if ($remote_url | is-empty) { print -e "  ✗ no URL provided"; return }
        let ra = (do { git -C $repo remote add origin $remote_url } | complete)
        if $ra.exit_code != 0 { print -e $"(ansi red_bold)  ✗ remote add failed:(ansi reset) ($ra.stderr)"; return }
        print $"(ansi green)  ✓ remote → ($remote_url)(ansi reset)"
    }

    # ── BOOKMARK ─────────────────────────────────────────────────────────────
    let bookmark = (resolve-bookmark $repo)
    let bm = if ($bookmark | is-empty) {
        let git_branch = (try { git -C $repo branch --show-current | str trim } catch { "" })
        let name = if ($git_branch | is-not-empty) { $git_branch } else { $config.default_branch }
        print $"(ansi yellow)  ⚠ no bookmark — creating ($name)(ansi reset)"
        let bmc = (do { jj --repository $repo bookmark create $name --at '@-' } | complete)
        if $bmc.exit_code != 0 {
            print $"(ansi yellow)  ⚠ bookmark create failed \(non-fatal\): ($bmc.stderr)(ansi reset)"
            ""
        } else {
            print $"(ansi green)  ✓ bookmark ($name) created(ansi reset)"
            $name
        }
    } else { $bookmark }

    let author_flag = $"($config.author_name) <($config.author_email)>"
    let pre_op_id   = (snapshot-op-id $repo)
    let steps = [
        { name: "INIT"   }
        { name: "FETCH"  }
        { name: "CHECK"  }
        { name: "COMMIT" }
        { name: "PUSH"   }
    ]
    mut timings   = {}
    mut checklist = []

    # ── INIT ─────────────────────────────────────────────────────────────────
    rh-flow $steps "INIT" $timings
    let t = (date now)
    print $"(ansi grey)  author  ($config.author_name) <($config.author_email)>(ansi reset)"
    let elapsed_init = $"(((date now) - $t) / 1sec * 1000 | math round)ms"
    $timings   = ($timings | insert INIT $elapsed_init)
    $checklist = ($checklist | append { stage: "INIT"  result: "✓"  elapsed: $elapsed_init  note: $"repo: ($repo)" })

    # ── FETCH ────────────────────────────────────────────────────────────────
    rh-flow $steps "FETCH" $timings
    let t = (date now)
    if (has-dirty-working-copy $repo) {
        print $"(ansi yellow)  ⚠ working copy dirty — fetch may fold remote changes in(ansi reset)"
    }
    let fetch_result = (do { jj --repository $repo git fetch } | complete)
    let elapsed_fetch = $"(((date now) - $t) / 1sec * 1000 | math round)ms"
    if $fetch_result.exit_code != 0 {
        $checklist = ($checklist | append { stage: "FETCH"  result: "✗"  elapsed: $elapsed_fetch  note: "fetch failed" })
        render-checklist $checklist
        print -e $"(ansi red_bold)  ✗ fetch failed:(ansi reset) ($fetch_result.stderr)"
        return
    }
    $timings   = ($timings | insert FETCH $elapsed_fetch)
    $checklist = ($checklist | append { stage: "FETCH"  result: "✓"  elapsed: $elapsed_fetch  note: "ok" })

    # ── CHECK ────────────────────────────────────────────────────────────────
    rh-flow $steps "CHECK" $timings
    let t = (date now)
    if (check-behind $repo $bm)        { return }
    if (check-conflicts $repo)         { return }
    if (check-remote-reachable $repo)  { return }
    if (check-stash $repo)             { return }
    let changed       = (capture-changed $repo)
    let diff_stats    = (calculate-diff-stats $repo)
    let elapsed_check = $"(((date now) - $t) / 1sec * 1000 | math round)ms"
    $timings   = ($timings | insert CHECK $elapsed_check)
    $checklist = ($checklist | append { stage: "CHECK"  result: "✓"  elapsed: $elapsed_check  note: "all clear" })

    # ── NOTHING TO COMMIT ────────────────────────────────────────────────────
    if ($changed | is-empty) {
        print -n "\e[2J\e[H"
        print ""
        print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
        print $"(ansi grey)  Nothing to commit — working copy is clean.(ansi reset)"
        print ""
        render-checklist $checklist
        let stats  = (fetch-repo-stats-from $repo $bm)
        let status = (fetch-status-from $repo)
        render-position $stats $status $diff_stats
        render-history (fetch-commits-from $repo $config.commits_to_show)
        print ""
        return
    }

    # ── COMMIT ───────────────────────────────────────────────────────────────
    rh-flow $steps "COMMIT" $timings
    let t = (date now)
    let commit_msg = if ($msg == "update") {
        let ts = (date now | format date "%Y-%m-%d %H:%M")
        if ($bm | is-not-empty) { $"[($bm)] ($ts)" } else { $"[no-bookmark] ($ts)" }
    } else { $msg }

    let desc_result = (do { jj --repository $repo metaedit -m $commit_msg --author $author_flag } | complete)
    if $desc_result.exit_code != 0 {
        $checklist = ($checklist | append { stage: "COMMIT"  result: "✗"  elapsed: "—"  note: "metaedit failed" })
        render-checklist $checklist
        print -e $"(ansi red_bold)  ✗ metaedit failed:(ansi reset) ($desc_result.stderr)"
        return
    }

    if ($bm | is-not-empty) {
        let bms = (do { jj --repository $repo bookmark set $bm -r '@' } | complete)
        if $bms.exit_code != 0 { print $"(ansi yellow)  ⚠ bookmark set: ($bms.stderr)(ansi reset)" }
    }

    let new_result = (do { jj --repository $repo new } | complete)
    if $new_result.exit_code != 0 {
        $checklist = ($checklist | append { stage: "COMMIT"  result: "✗"  elapsed: "—"  note: "jj new failed" })
        render-checklist $checklist
        print -e $"(ansi red_bold)  ✗ jj new failed:(ansi reset) ($new_result.stderr)"
        return
    }
    let elapsed_commit = $"(((date now) - $t) / 1sec * 1000 | math round)ms"
    $timings   = ($timings | insert COMMIT $elapsed_commit)
    $checklist = ($checklist | append { stage: "COMMIT"  result: "✓"  elapsed: $elapsed_commit  note: $commit_msg })

    # ── PUSH ─────────────────────────────────────────────────────────────────
    rh-flow $steps "PUSH" $timings
    let t = (date now)
    let push_result   = (do-push $repo $bm)
    let elapsed_push  = $"(((date now) - $t) / 1sec * 1000 | math round)ms"
    if $push_result.exit_code != 0 {
        $checklist = ($checklist | append { stage: "PUSH"  result: "✗"  elapsed: $elapsed_push  note: "remote rejected" })
        render-checklist $checklist
        render-push-failure $push_result.stderr
        return
    }
    $timings   = ($timings | insert PUSH $elapsed_push)
    $checklist = ($checklist | append { stage: "PUSH"  result: "✓"  elapsed: $elapsed_push  note: $"→ ($bm)" })

    # ── SUMMARY ──────────────────────────────────────────────────────────────
    rh-flow $steps "" $timings
    try { jj --repository $repo git fetch } catch { }
    let stats   = (fetch-repo-stats-from $repo $bm)
    let status  = (fetch-status-from $repo)
    let commits = (fetch-commits-from $repo $config.commits_to_show)
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  pushed  ($bm)  (date now | format date '%Y-%m-%d %H:%M')(ansi reset)"
    print ""
    render-checklist $checklist
    render-impact $changed
    render-position $stats $status $diff_stats
    render-history $commits
    render-op-log $repo $pre_op_id
    print ""
}
# =============================================================================
# SECTION 8 — CONVENIENCE COMMANDS
# =============================================================================
def jj-undo [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let result = (do { jj --repository $repo op undo } | complete)
    if $result.exit_code != 0 { print -e $"(ansi red_bold)  ✗ undo failed:(ansi reset) ($result.stderr)" }
    else { print $"(ansi green)  ✓ undone(ansi reset)"; fetch-op-log-from $repo 3 | print }
}

def jj-restore-op [op_id: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let result = (do { jj --repository $repo op restore $op_id } | complete)
    if $result.exit_code != 0 { print -e $"(ansi red_bold)  ✗ restore failed:(ansi reset) ($result.stderr)" }
    else { print $"(ansi green)  ✓ restored to ($op_id)(ansi reset)" }
}

def jj-bookmark-here [name: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    jj --repository $repo bookmark set $name -r '@-'
    do-push $repo $name
    print $"(ansi green)  ✓ bookmark ($name) set on @- and pushed(ansi reset)"
}

def jj-fix-authors [] {
    # Rewrite all mutable commits to have the correct author. Run this once to fix a poisoned history.
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let author_flag = $"($config.author_name) <($config.author_email)>"
    jj --repository $repo log --no-graph -r 'mutable()' --template 'change_id.short(8) ++ "\n"'
    | lines | where { |l| $l | is-not-empty }
    | each { |id|
        let r = (do { jj --repository $repo metaedit -r $id --author $author_flag } | complete)
        if $r.exit_code != 0 and not ($r.stderr | str contains "Nothing changed") {
            print $"(ansi yellow)  ⚠ ($id): ($r.stderr)(ansi reset)"
        }
    }
    print $"(ansi green)  ✓ authors fixed(ansi reset)"
}

def jj-split  [] { let repo = (find-repo-root); if $repo == null { return }; jj --repository $repo split }
def jj-squash [] { let repo = (find-repo-root); if $repo == null { return }; jj --repository $repo squash }
def jj-evolog [] { let repo = (find-repo-root); if $repo == null { return }; jj --repository $repo evolog }

def jj-stats-json [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let bm = (resolve-bookmark $repo | default "")
    fetch-repo-stats-from $repo $bm --json
}
# =============================================================================
# SECTION 9 — KEYBINDINGS
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