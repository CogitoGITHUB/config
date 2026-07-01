# =============================================================================
# ManifoldOS — Reshaping History
# =============================================================================
let config = {
    max_file_size_mb: 5
    verbose_failures: true
    commits_to_show:  10
    author_name:      "CogitoGITHUB"
    author_email:     "vlasceanupaulinoionut@gmail.com"
    default_branch:   "master"
    github_user:      "CogitoGITHUB"
    github_token_path: null
}

# =============================================================================
# SECTION 0 — REPO DETECTION + BOOTSTRAP
# =============================================================================
def find-repo-root [] {
    mut dir = (pwd)
    loop {
        if ($dir | path join ".git" | path exists) { return $dir }
        let parent = ($dir | path dirname)
        if $parent == $dir { return null }
        $dir = $parent
    }
}

def get-github-token [] {
    let secrets_dir = ($env.HOME | path join ".secrets")
    let token_path  = ($secrets_dir | path join "github_token")
    let gitignore   = ($secrets_dir | path join ".gitignore")
    if not ($secrets_dir | path exists) { mkdir $secrets_dir }
    if not ($gitignore   | path exists) { "*" | save -f $gitignore }
    if ($token_path | path exists) { return (open $token_path | str trim) }
    print -n "\e[2J\e[H"
    print $"(ansi red_bold)🌹 MANIFOLD // GITHUB TOKEN SETUP 🌹(ansi reset)"
    try { xdg-open "https://github.com/settings/tokens/new?scopes=repo&description=ManifoldOS" } catch {
        print "  https://github.com/settings/tokens/new?scopes=repo&description=ManifoldOS"
    }
    let token = (input "  Paste token: " | str trim)
    if ($token | is-empty) { return null }
    $token | save -f $token_path
    chmod 600 $token_path
    print $"(ansi green)  ✓ saved(ansi reset)"
    $token
}

def get-gitlab-token [] {
    let secrets_dir = ($env.HOME | path join ".secrets")
    let token_path  = ($secrets_dir | path join "gitlab_token")
    let gitignore   = ($secrets_dir | path join ".gitignore")
    if not ($secrets_dir | path exists) { mkdir $secrets_dir }
    if not ($gitignore   | path exists) { "*" | save -f $gitignore }
    if ($token_path | path exists) { return (open $token_path | str trim) }
    print -n "\e[2J\e[H"
    print $"(ansi red_bold)🌹 MANIFOLD // GITLAB TOKEN SETUP 🌹(ansi reset)"
    try { xdg-open "https://gitlab.com/-/profile/personal_access_tokens?name=ManifoldOS&scopes=api" } catch {
        print "  https://gitlab.com/-/profile/personal_access_tokens?name=ManifoldOS&scopes=api"
    }
    let token = (input "  Paste token: " | str trim)
    if ($token | is-empty) { return null }
    $token | save -f $token_path
    chmod 600 $token_path
    print $"(ansi green)  ✓ saved(ansi reset)"
    $token
}

def github-create-repo [name: string, token: string] {
    let body = ({ name: $name, private: false, auto_init: false } | to json)
    let gh_headers = { Authorization: $"Bearer ($token)", "User-Agent": $config.author_name, Accept: "application/vnd.github+json" }
    let resp = (try {
        http post --content-type "application/json" --full --allow-errors --headers $gh_headers "https://api.github.com/user/repos" $body
    } catch { |err| print -e $"  ✗ GitHub API failed: ($err.msg)"; return null })
    if $resp.status == 201 { 
        $resp.body.ssh_url 
    } else if $resp.status == 422 {
        try {
            http get --full --allow-errors --headers $gh_headers $"https://api.github.com/repos/($config.github_user)/($name)" | .body.ssh_url
        } catch { null }
    } else { null }
}

def gitlab-create-repo [name: string, token: string] {
    let body = ({ name: $name, visibility: "public", initialize_with_readme: false } | to json)
    try {
        let gl_headers = { "PRIVATE-TOKEN": $token, "User-Agent": $config.author_name }
        let resp = (http post --content-type "application/json" --full --allow-errors --headers $gl_headers "https://gitlab.com/api/v4/projects" $body)
        if $resp.status == 201 { $resp.body.ssh_url_to_repo } else { null }
    } catch { null }
}

def ensure-ssh-key [] {
    let key_path = ($env.HOME | path join ".ssh" "id_ed25519")
    let pub_path = $"($key_path).pub"
    if not ($key_path | path exists) {
        let r = (do { ssh-keygen -t ed25519 -C $config.author_email -f $key_path -N "" } | complete)
        if $r.exit_code != 0 { return false }
    }
    let test = (do { ssh -T git@github.com -o StrictHostKeyChecking=accept-new -o BatchMode=yes } | complete)
    let authed = ($test.stderr | str contains "successfully authenticated") or ($test.stdout | str contains "successfully authenticated")
    if $authed { return true }
    let pub = (open $pub_path | str trim)
    print $"  ($pub)"
    try { xdg-open "https://github.com/settings/ssh/new" } catch { }
    input "  Press Enter once you've saved the key on GitHub... " | ignore
    true
}

def ensure-git-initialized [repo: string] {
    git -C $repo config user.name  $config.author_name
    git -C $repo config user.email $config.author_email
    true
}

def bootstrap-repo [] {
    let repo = (pwd)
    let repo_name = ($repo | path basename)
    print -n "\e[2J\e[H"
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  Bootstrapping ($repo_name)(ansi reset)"
    let provider = (["GitHub" "GitLab"] | input list --fuzzy "Push to:")
    let token = if $provider == "GitHub" { get-github-token } else { get-gitlab-token }
    if $token == null { return false }
    let remote_url = if $provider == "GitHub" {
        github-create-repo $repo_name $token
    } else {
        gitlab-create-repo $repo_name $token
    }
    if $remote_url == null { return false }
    let gi = (do { git init $repo } | complete)
    if $gi.exit_code != 0 { return false }
    git -C $repo config user.name  $config.author_name
    git -C $repo config user.email $config.author_email
    let ra = (do { git -C $repo remote add origin $remote_url } | complete)
    if $ra.exit_code != 0 { return false }
    let bm = $config.default_branch
    let cb = (do { git -C $repo checkout -b $bm } | complete)
    if $cb.exit_code != 0 { return false }
    let needs_file = (try { (git -C $repo status --short | str trim | is-empty) } catch { true })
    if $needs_file { ".gitkeep" | save -f ($repo | path join ".gitkeep") }
    git -C $repo add -A | ignore
    let ts = (date now | format date "%Y-%m-%d %H:%M")
    let ci = (do { git -C $repo commit -m $"[($bm)] init ($ts)" --author $"($config.author_name) <($config.author_email)>" } | complete)
    if $ci.exit_code != 0 { return false }
    if ($remote_url | str starts-with "git@") or ($remote_url | str starts-with "ssh://") {
        if not (ensure-ssh-key) { return false }
    }
    let pr = (do { git -C $repo push -u origin $bm } | complete)
    if $pr.exit_code != 0 {
        let pr2 = (do { git -C $repo push -u origin $bm } | complete)
        if $pr2.exit_code != 0 { return false }
    }
    print $"(ansi green)  ✓ pushed → ($remote_url) on ($bm)(ansi reset)"
    true
}

# =============================================================================
# SECTION 1 — DELIMITER
# =============================================================================
const SEP = "\u{001E}"

# =============================================================================
# SECTION 2 — DATA COLLECTION
# =============================================================================
def list-branches [repo: string] {
    try {
        git -C $repo branch
        | lines | where { |l| $l | is-not-empty }
        | each { |l| $l | str replace --regex '^\*?\s+' '' | str trim }
    } catch { [] }
}

def resolve-branch [repo: string] {
    let git_dir = ($repo | path join ".git")
    if ($git_dir | path join "rebase-merge"     | path exists) { return "__rebase__" }
    if ($git_dir | path join "rebase-apply"     | path exists) { return "__rebase__" }
    if ($git_dir | path join "MERGE_HEAD"       | path exists) { return "__merge__" }
    if ($git_dir | path join "CHERRY_PICK_HEAD" | path exists) { return "__cherry-pick__" }
    if ($git_dir | path join "BISECT_LOG"       | path exists) { return "__bisect__" }
    let branch = (try { git -C $repo branch --show-current | str trim } catch { "" })
    if ($branch | is-not-empty) { return $branch }
    let hash = (try { git -C $repo rev-parse --short HEAD | str trim } catch { "" })
    if ($hash | is-not-empty) { return $"__detached__($hash)" }
    ""
}

def resolve-ahead-behind [repo: string, branch: string] {
    let remote_exists = (try {
        (do { git -C $repo rev-parse --verify $"origin/($branch)" } | complete).exit_code == 0
    } catch { false })
    if not $remote_exists { return { ahead: 0  behind: 0 } }
    let ahead  = (try { do { git -C $repo rev-list --count $"origin/($branch)..($branch)" } | complete | get stdout | str trim | into int } catch { 0 })
    let behind = (try { do { git -C $repo rev-list --count $"($branch)..origin/($branch)" } | complete | get stdout | str trim | into int } catch { 0 })
    { ahead: $ahead  behind: $behind }
}

def capture-changed [repo: string] {
    try {
        let raw = (do { git -C $repo status --porcelain=v1 -z } | complete)
        if $raw.exit_code != 0 { return [] }
        let tokens = ($raw.stdout | split row "\u{0000}" | where { |t| $t | is-not-empty })
        mut results = []
        mut i = 0
        while $i < ($tokens | length) {
            let tok    = ($tokens | get $i)
            let x      = ($tok | str substring 0..0)
            let y      = ($tok | str substring 1..1)
            let fname  = ($tok | str substring 3..)
            let code   = if $x != " " and $x != "?" { $x } else { $y }
            let status = match $code {
                "A" => "added"   "D" => "deleted" "M" => "modified"
                "R" => "renamed" "C" => "copied"  "U" => "unmerged"
                "?" => "untracked" _ => "changed"
            }
            if $x == "R" or $x == "C" { $i = $i + 1 }
            $results = ($results | append { status: $status  file: $fname })
            $i = $i + 1
        }
        $results
    } catch { [] }
}

# =============================================================================
# SECTION 3 — SAFETY CHECKS
# =============================================================================
def remote-branch-exists [repo: string, branch: string] {
    try { (do { git -C $repo rev-parse --verify $"origin/($branch)" } | complete).exit_code == 0 } catch { false }
}

def check-remote-reachable [repo: string] {
    let url = (try { git -C $repo remote get-url origin | str trim } catch { "" })
    if ($url | is-empty) { return false }
    if not ($url | str starts-with "git@") { return false }
    let host = (try { $url | split row ":" | get 0 | str replace "git@" "" } catch { "" })
    if ($host | is-empty) { return false }
    let r = (do { ssh -T $"git@($host)" -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=5 } | complete)
    let ok = ($r.stderr | str contains "successfully authenticated") or ($r.stdout | str contains "successfully authenticated") or ($r.exit_code == 1)
    if not $ok {
        print $"(ansi red_bold)  🥀 REMOTE UNREACHABLE — cannot reach ($host) via SSH(ansi reset)"
        true
    } else { false }
}

def check-divergence [repo: string, branch: string] {
    if ($branch | is-empty) { return false }
    if not (remote-branch-exists $repo $branch) { return false }
    let ahead  = (try { git -C $repo rev-list --count $"origin/($branch)..($branch)" | str trim | into int } catch { 0 })
    let behind = (try { git -C $repo rev-list --count $"($branch)..origin/($branch)" | str trim | into int } catch { 0 })
    if $ahead == 0 or $behind == 0 { return false }
    print $"(ansi red_bold)  🥀 DIVERGED — ($branch) is ($ahead) ahead, ($behind) behind(ansi reset)"
    let choice = (["rebase onto remote" "abort"] | input list --fuzzy "Divergence strategy:")
    if $choice == "abort" { return true }
    let r = (do { git -C $repo rebase $"origin/($branch)" } | complete)
    if $r.exit_code != 0 { git -C $repo rebase --abort | ignore; return true }
    git -C $repo fetch origin | ignore
    false
}

def check-behind [repo: string, branch: string] {
    if ($branch | is-empty) { return false }
    if not (remote-branch-exists $repo $branch) { return false }
    let behind = (try { git -C $repo rev-list --count $"($branch)..origin/($branch)" | str trim | into int } catch { 0 })
    if $behind == 0 { return false }
    print $"(ansi red_bold)  🥀 BEHIND REMOTE — ($branch) is ($behind) commit\(s\) behind(ansi reset)"
    let choice = ([
        "fast-forward  — rebase local commits on top of remote (recommended)"
        "pull only     — move branch to remote tip, discard local"
        "abort         — exit and handle manually"
    ] | input list --fuzzy "Behind remote — how to proceed?")
    if ($choice | str starts-with "abort") { return true }
    if ($choice | str starts-with "fast-forward") {
        let local_only = (try { git -C $repo rev-list --count $"origin/($branch)..($branch)" | str trim | into int } catch { 0 })
        if $local_only == 0 {
            let r = (do { git -C $repo merge --ff-only $"origin/($branch)" } | complete)
            if $r.exit_code != 0 { return true }
        } else {
            let r = (do { git -C $repo rebase $"origin/($branch)" } | complete)
            if $r.exit_code != 0 { git -C $repo rebase --abort | ignore; return true }
        }
        git -C $repo fetch origin | ignore
        return false
    }
    if ($choice | str starts-with "pull only") {
        let local_only = (try { git -C $repo rev-list --count $"origin/($branch)..($branch)" | str trim | into int } catch { 0 })
        if $local_only > 0 {
            let confirm = (["yes — discard them" "no — abort"] | input list --fuzzy "Discard local commits?")
            if not ($confirm | str starts-with "yes") { return true }
        }
        let r = (do { git -C $repo reset --hard $"origin/($branch)" } | complete)
        if $r.exit_code != 0 { return true }
        git -C $repo fetch origin | ignore
        return false
    }
    true
}

def check-conflicts [repo: string] {
    let conflicted = (try { git -C $repo diff --name-only --diff-filter=U | lines | where { |l| $l | is-not-empty } } catch { [] })
    if not ($conflicted | is-empty) {
        print $"(ansi red_bold)  🥀 UNRESOLVED CONFLICTS(ansi reset)"
        $conflicted | print
        ["abort"] | input list --fuzzy "Resolve manually then re-run:" | ignore
        return true
    }
    false
}

def check-large-files [repo: string] {
    let limit = ($config.max_file_size_mb * 1mb)
    let large = (try {
        git -C $repo status --porcelain=v1 -z
        | split row "\u{0000}" | where { |t| $t | is-not-empty }
        | each { |tok|
            let fname = ($tok | str substring 3..)
            let full  = ($repo | path join $fname)
            if not ($full | path exists) { return null }
            let sz = (try { (ls $full).0.size } catch { 0b })
            if $sz > $limit { $fname } else { null }
        }
        | where { |x| $x != null }
    } catch { [] })
    if not ($large | is-empty) {
        print $"(ansi red_bold)  🥀 LARGE FILES — ($config.max_file_size_mb)MB limit exceeded(ansi reset)"
        $large | print
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Large files — proceed?")
        $choice == "abort"
    } else { false }
}

def check-stash [repo: string] {
    let count = (try { git -C $repo stash list | lines | length } catch { 0 })
    if $count > 0 {
        print $"(ansi red_bold)  🥀 STASHED CHANGES — ($count) stashes(ansi reset)"
        git -C $repo stash list | lines | print
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Stash detected — proceed?")
        $choice == "abort"
    } else { false }
}

def check-gitignore [repo: string] {
    let danger_patterns = [
        ".env" ".env.local" ".env.*" "*.pem" "*.key" "*.p12" "*.pfx" "*.cer"
        "id_rsa" "id_ed25519" "id_ecdsa" "node_modules" "__pycache__" "*.pyc"
        "dist/" "build/" ".next/" "target/"
    ]
    let staged = (try {
        git -C $repo status --porcelain=v1 -z
        | split row "\u{0000}"
        | where { |t| ($t | is-not-empty) and ($t | str substring 0..0) != " " and ($t | str substring 0..0) != "?" }
        | each { |tok| $tok | str substring 3.. }
    } catch { [] })
    let suspicious = ($staged | where { |f|
        $danger_patterns | any { |pat|
            ($f | str ends-with ($pat | str replace "*" "")) or ($f | str contains "node_modules") or ($f | str contains "__pycache__")
        }
    })
    if not ($suspicious | is-empty) {
        print $"(ansi red_bold)  🥀 SUSPICIOUS FILES(ansi reset)"
        $suspicious | print
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Suspicious files — proceed?")
        $choice == "abort"
    } else { false }
}

# =============================================================================
# SECTION 4 — PUSH HELPER
# =============================================================================
def do-push [repo: string, branch: string] {
    (do { git -C $repo push --set-upstream origin $branch } | complete)
}

# =============================================================================
# SECTION 5 — RENDER
# =============================================================================
def render-summary [bm: string, changed: list, commit_msg: string, sync: record, elapsed: string] {
    let rose = "🌹"
    let wilt = "🥀"
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)  ($rose) ($bm)  ↑($sync.ahead) ↓($sync.behind)  ($elapsed)(ansi reset)"
    print ""
    print $"(ansi red)  ($rose) ($commit_msg)(ansi reset)"
    print ""
    for f in $changed {
        let sym = match $f.status { "deleted" => $wilt _ => $rose }
        print $"(ansi red)  ($sym) ($f.status)  ($f.file)(ansi reset)"
    }
    print ""
     let total   = ($changed | length)
     let deleted = ($changed | where status == "deleted" | length)
     let health  = (if $total == 0 { $"(ansi red)nothing changed(ansi reset)" }
         else if $deleted == $total { $"(ansi red)($wilt)($wilt)($wilt)  everything was lost(ansi reset)" }
         else if $deleted > ($total / 2 | math floor) { $"(ansi red)($rose)($wilt)($wilt)  the history shifts(ansi reset)" }
         else { $"(ansi red)($rose)($rose)($rose)($rose)($rose)  the history has been reshaped(ansi reset)" })
     print $"  ($health)"
     print ""
}

def render-failure [stage: string, reason: string] {
    print $"(ansi red_bold)  🥀 ($stage) FAILED(ansi reset)"
    print $"(ansi grey)  ($reason)(ansi reset)"
}

# =============================================================================
# SECTION 6 — FZF WRAPPER
# =============================================================================
def fzf-run [input_str: string, args: list<string>] {
    do { $input_str | run-external "fzf" ...$args } | complete
}

# =============================================================================
# SECTION 7 — HUB ACTIONS
# =============================================================================

# ── commit & push ─────────────────────────────────────────────────────────────
def hub-commit-push [repo: string, bm: string, msg: string] {
    print $"(ansi red)  🌹 fetching...(ansi reset)"
    let fetch_result = (do { git -C $repo fetch origin } | complete)
    if $fetch_result.exit_code != 0 { render-failure "FETCH" $fetch_result.stderr; return }
    if (check-divergence $repo $bm)   { return }
    if (check-behind $repo $bm)       { return }
    if (check-conflicts $repo)        { return }
    if (check-stash $repo)            { return }
    if (check-large-files $repo)      { return }
    if (check-gitignore $repo)        { return }
    let changed = (capture-changed $repo)
    if ($changed | is-empty) { print $"  🌹 ($bm)  nothing to reshape"; return }
    let commit_msg = if ($msg == "update") {
        $"[($bm)] (date now | format date '%Y-%m-%d %H:%M')"
    } else { $msg }
    let author = $"($config.author_name) <($config.author_email)>"
    print $"(ansi red)  🌹 staging & committing...(ansi reset)"
    git -C $repo add -A | ignore
    let ci = (do { git -C $repo commit -m $commit_msg --author $author } | complete)
    if $ci.exit_code != 0 { render-failure "COMMIT" $ci.stderr; return }
    print $"(ansi red)  🌹 pushing...(ansi reset)"
    let pr = (do-push $repo $bm)
    if $pr.exit_code != 0 { render-failure "PUSH" $pr.stderr; return }
    try { git -C $repo fetch origin } catch { }
    let sync    = (resolve-ahead-behind $repo $bm)
    render-summary $bm $changed $commit_msg $sync "done"
}

# ── branches ──────────────────────────────────────────────────────────────────
def branch-fzf-lines [repo: string] {
    try {
        git -C $repo branch
        | lines | where { |l| $l | is-not-empty }
        | each { |l|
            let is_current = ($l | str starts-with "*")
            let name   = ($l | str replace --regex '^\*?\s+' '' | str trim)
            let marker = if $is_current { $"(ansi green_bold)*(ansi reset)" } else { " " }
            let sync   = (resolve-ahead-behind $repo $name)
            let last   = (try { git -C $repo log -1 "--format=%h  %ar  %s" $name | str trim } catch { "no commits" })
            $"($marker)\t($name)\t↑($sync.ahead) ↓($sync.behind)\t($last)"
        }
    } catch { [] }
}

def hub-branches [repo: string] {
    loop {
        let lines = (branch-fzf-lines $repo | str join "\n")
        if ($lines | str trim | is-empty) { print "  🥀 no branches"; return }

        let preview = $"git -C ($repo) log --oneline --color=always -12 {2}"
        let current = (resolve-branch $repo)
        let result  = (fzf-run $lines [
            "--ansi"
            "--tabstop=1"
            "--delimiter=\t"
            "--with-nth=2.."
            "--nth=1"
            "--prompt=  🌹 branch  "
            $"--header=($current)  enter=switch  ctrl-n=new  ctrl-d=delete  esc=back"
            $"--preview=($preview)"
            "--preview-window=right:45%:wrap"
            "--expect=ctrl-d,ctrl-n"
            "--bind=esc:abort"
        ])

        if ($result.stdout | is-empty) { return }

        # --expect outputs the key name as first line for ALL keys including enter
        let all_lines = ($result.stdout | lines)
        let key = ($all_lines | first | str trim)
        let selected = ($all_lines | skip 1 | str join "\n" | str trim)

        if $key == "ctrl-d" {
            let target = ($selected | split row "\t" | get 0 | str trim)
            if ($target | is-empty) { continue }
            let current = (resolve-branch $repo)
            if $target == $current { print "  🥀 cannot delete current branch"; continue }
            let unpushed = (try { do { git -C $repo rev-list --count $"origin/($target)..($target)" } | complete | get stdout | str trim | into int } catch { 0 })
            let unpushed_msg = if $unpushed > 0 {
                " (" + ($unpushed | into string) + ") unpushed"
            } else { "" }
            print -n $"  delete ($target)($unpushed_msg)? [y/N] "
            let yn = (input "" | str trim | str downcase)
            if $yn == "y" {
                git -C $repo branch -D $target | ignore
                if (remote-branch-exists $repo $target) {
                    git -C $repo push origin --delete $target | ignore
                    print $"  🌹 ($target) deleted locally and on remote"
                } else {
                    print $"  🌹 ($target) deleted locally"
                }
                input "  Press enter..." | ignore
            }
            continue
        }

        if $key == "ctrl-n" {
            print -n "  🌹 new branch name: "
            let name = (input "" | str trim)
            if ($name | is-empty) { continue }
            let cb = (do { git -C $repo checkout -b $name } | complete)
            if $cb.exit_code != 0 { print -e $"  🥀 ($cb.stderr)" } else { print $"  🌹 switched to ($name)" }
            input "  Press enter..." | ignore
            continue
        }

        if $key == "enter" {
            let parts = ($selected | split row "\t")
            let target = if ($parts | length) > 0 { $parts | get 0 } else { $selected }
            if ($target | is-empty) { return }

            let current = (resolve-branch $repo)
            if $target == $current { print $"  🌹 already on ($target)"; continue }

            let dirty = (try { git -C $repo status --porcelain | length } catch { 0 })
            mut stash_yn = "n"
            if $dirty > 0 {
                print -n "  🌹 stash changes before switching? [Y/n] "
                $stash_yn = (input "" | str trim | str downcase)
            }
            if $dirty > 0 and $stash_yn != "n" {
                let stash_ok = (do { git -C $repo stash push -m "auto-stash before branch switch" } | complete)
                if $stash_ok.exit_code == 0 {
                    print "  🌹 stashed"
                } else {
                    print -e $"  🥀 stash failed: ($stash_ok.stderr | str trim)"
                    continue
                }
            }

            let checkout = (do { git -C $repo checkout $target } | complete)
            if $checkout.exit_code == 0 {
                if $dirty > 0 and $stash_yn != "n" {
                    let pop_ok = (do { git -C $repo stash pop } | complete)
                    if $pop_ok.exit_code != 0 {
                        print -e $"  �0 stash pop failed — run 'git stash drop' to clean up: ($pop_ok.stderr | str trim)"
                    }
                }
                print $"  🌹 switched to ($target)"
                input "  Press enter..." | ignore
                return
            } else {
                print -e $"  🥀 checkout failed: ($checkout.stderr)"
                input "  Press enter..." | ignore
            }
        }
    }
}

# ── log ───────────────────────────────────────────────────────────────────────
def hub-log [repo: string] {
    let sentinel = ($env.HOME | path join ".manifold_action")
    let lines = (try {
        git -C $repo log "--format=%h\t%ar\t%s\t%an" --color=never -40
        | lines | where { |l| $l | is-not-empty }
    } catch { [] })
    if ($lines | is-empty) { print "  🥀 no commits"; return }

    let preview  = $"git -C ($repo) show --color=always {1}"
    let bind_tag = $"ctrl-t:execute(echo __tag__:{1} > ($sentinel))+abort"
    let bind_br  = $"ctrl-b:execute(echo __branch__:{1} > ($sentinel))+abort"
    let bind_rst = $"ctrl-u:execute(echo __undo__:{1} > ($sentinel))+abort"

    let result = (fzf-run ($lines | str join "\n") [
        "--ansi"
        "--tabstop=1"
        "--delimiter=\t"
        "--with-nth=1,2,3"
        "--prompt=  🌹 log  "
        "--header=  enter=inspect  ctrl-t=tag  ctrl-b=branch-here  ctrl-u=reset-to  esc=back"
        $"--preview=($preview)"
        "--preview-window=right:55%:wrap"
        $"--bind=($bind_tag)"
        $"--bind=($bind_br)"
        $"--bind=($bind_rst)"
        "--bind=esc:abort"
    ])

    let action = (
        if ($sentinel | path exists) {
            let v = (open $sentinel | str trim); rm -f $sentinel; $v
        } else { "" }
    )

    let hash = (
        if ($action | str contains ":") { $action | split row ":" | get 1 | str trim }
        else if $result.exit_code == 0  { $result.stdout | str trim | split row "\t" | get 0 }
        else { "" }
    )
    if ($hash | is-empty) { return }

    if ($action | str starts-with "__tag__") {
        print -n $"  🌹 tag name for ($hash): "
        let tag = (input "" | str trim)
        if ($tag | is-empty) { return }
        git -C $repo tag $tag $hash | ignore
        git -C $repo push origin $tag | ignore
        print $"  🌹 tag ($tag) pushed"
        input "  Press enter..." | ignore
        return
    }
    if ($action | str starts-with "__branch__") {
        print -n $"  🌹 branch name at ($hash): "
        let name = (input "" | str trim)
        if ($name | is-empty) { return }
        git -C $repo branch $name $hash | ignore
        print $"  🌹 branch ($name) created at ($hash)"
        input "  Press enter..." | ignore
        return
    }
    if ($action | str starts-with "__undo__") {
        print -n $"  reset HEAD to ($hash)? This discards all commits after it. [y/N] "
        let yn = (input "" | str trim | str downcase)
        if $yn == "y" {
            let r = (do { git -C $repo reset --hard $hash } | complete)
            if $r.exit_code != 0 { print -e $"  🥀 ($r.stderr)" } else { print $"  🌹 reset to ($hash)" }
            let current = (try { git -C $repo branch --show-current | str trim } catch { "" })
            if ($current | is-empty) {
                let nearby = (try {
                    git -C $repo branch --contains HEAD | lines | where { |l| $l | is-not-empty }
                    | each { |l| $l | str replace --regex '^\*?\s+' '' }
                } catch { [] })
                if not ($nearby | is-empty) {
                    let target = ($nearby | first)
                    git -C $repo checkout $target | ignore
                    print $"  🌹 re-attached to ($target)"
                } else {
                    print -n "  create new branch at this commit? name: "
                    let name = (input "" | str trim)
                    if ($name | is-not-empty) {
                        git -C $repo checkout -b $name | ignore
                        print $"  🌹 switched to new branch ($name)"
                    }
                }
            }
            input "  Press enter..." | ignore
        }
        return
    }
    # enter — just show full commit
    git -C $repo show --stat $hash | print
    input "  Press enter..." | ignore
}

# ── stash ─────────────────────────────────────────────────────────────────────
def hub-stash [repo: string] {
    let sentinel = ($env.HOME | path join ".manifold_action")
    loop {
        let lines = (try { git -C $repo stash list | lines | where { |l| $l | is-not-empty } } catch { [] })
        if ($lines | is-empty) { print "  🌹 no stashes"; input "  Press enter..." | ignore; return }

        # Extract stash ref (stash@{N}) for preview and actions
        let preview  = $"git -C ($repo) stash show -p --color=always {1}"
        let bind_drop = $"ctrl-d:execute(echo __drop__:{1} > ($sentinel))+abort"

        let result = (fzf-run ($lines | str join "\n") [
            "--ansi"
            "--prompt=  🌹 stash  "
            "--header=  enter=pop  ctrl-a=apply  ctrl-d=drop  esc=back"
            $"--preview=($preview)"
            "--preview-window=right:55%:wrap"
            $"--bind=ctrl-a:execute(echo __apply__:{1} > ($sentinel))+abort"
            $"--bind=($bind_drop)"
            "--bind=esc:abort"
        ])

        let action = (
            if ($sentinel | path exists) {
                let v = (open $sentinel | str trim); rm -f $sentinel; $v
            } else { "" }
        )

        let ref = (
            if ($action | str contains ":") {
                $action | split row ":" | get 1 | str trim
            } else if $result.exit_code == 0 {
                $result.stdout | str trim | split row ":" | get 0
            } else { "" }
        )
        if ($ref | is-empty) { return }

        if ($action | str starts-with "__apply__") {
            let r = (do { git -C $repo stash apply $ref } | complete)
            if $r.exit_code != 0 { print -e $"  🥀 ($r.stderr)" } else { print $"  🌹 stash applied" }
            input "  Press enter..." | ignore
            continue
        }
        if ($action | str starts-with "__drop__") {
            print -n $"  drop ($ref)? [y/N] "
            let yn = (input "" | str trim | str downcase)
            if $yn == "y" {
                git -C $repo stash drop $ref | ignore
                print $"  🌹 stash dropped"
                input "  Press enter..." | ignore
            }
            continue
        }
        # enter — pop
        let r = (do { git -C $repo stash pop $ref } | complete)
        if $r.exit_code != 0 { print -e $"  🥀 ($r.stderr)" } else { print $"  🌹 stash popped" }
        input "  Press enter..." | ignore
        return
    }
}

# ── diff ──────────────────────────────────────────────────────────────────────
def hub-diff [repo: string] {
    let changed = (capture-changed $repo)
    if ($changed | is-empty) { print "  🌹 nothing changed"; input "  Press enter..." | ignore; return }
    let lines = ($changed | each { |f| $"($f.status)\t($f.file)" } | str join "\n")
    let preview = $"git -C ($repo) diff --color=always -- {2}"
    fzf-run $lines [
        "--ansi"
        "--tabstop=1"
        "--delimiter=\t"
        "--with-nth=1,2"
        "--prompt=  🌹 diff  "
        "--header=  browse changed files — esc=back"
        $"--preview=($preview)"
        "--preview-window=right:65%:wrap"
        "--bind=esc:abort"
    ] | ignore
}

# ── squash ────────────────────────────────────────────────────────────────────
def hub-squash [repo: string, bm: string] {
    let total = (try { git -C $repo rev-list --count HEAD | str trim | into int } catch { 0 })
    print $"  ($total) commits on ($bm). How many to squash?"
    print -n "  N: "
    let raw = (input "" | str trim)
    if ($raw | is-empty) { return }
    let n = (try { $raw | into int } catch { 0 })
    if $n < 2 { print "  🥀 need at least 2"; return }
    if $n >= $total { print $"  🥀 only ($total) commits exist"; return }
    let r = (do { git -C $repo reset --soft $"HEAD~($n)" } | complete)
    if $r.exit_code != 0 { print -e $"  🥀 ($r.stderr)"; return }
    let ts     = (date now | format date "%Y-%m-%d %H:%M")
    let author = $"($config.author_name) <($config.author_email)>"
    let ci = (do { git -C $repo commit -m $"[($bm)] squash ($ts)" --author $author } | complete)
    if $ci.exit_code != 0 { print -e $"  🥀 ($ci.stderr)"; return }
    print $"  🌹 squashed ($n) commits"
    input "  Press enter..." | ignore
}

# ── amend ─────────────────────────────────────────────────────────────────────
def hub-amend [repo: string] {
    let author = $"($config.author_name) <($config.author_email)>"
    git -C $repo add -A | ignore
    let r = (do { git -C $repo commit --amend --no-edit --author $author } | complete)
    if $r.exit_code != 0 { print -e $"  🥀 ($r.stderr)"; return }
    print "  🌹 amended HEAD"
    git -C $repo log --oneline -3 | print
    input "  Press enter..." | ignore
}

# ── undo ──────────────────────────────────────────────────────────────────────
def hub-undo [repo: string] {
    let has_parent = (try { (do { git -C $repo rev-parse HEAD~1 } | complete).exit_code == 0 } catch { false })
    if not $has_parent { print "  🥀 no parent commit"; return }
    let r = (do { git -C $repo reset --soft HEAD~1 } | complete)
    if $r.exit_code != 0 { print -e $"  🥀 ($r.stderr)"; return }
    print "  🌹 last commit undone — changes kept staged"
    git -C $repo status --short | print
    input "  Press enter..." | ignore
}

# ── sync ──────────────────────────────────────────────────────────────────────
def hub-sync [repo: string, bm: string] {
    print "  🌹 fetching..."
    let fetch = (do { git -C $repo fetch origin } | complete)
    if $fetch.exit_code != 0 { render-failure "FETCH" $fetch.stderr; return }
    if not (remote-branch-exists $repo $bm) { print $"  🌹 no remote ($bm) to sync"; input "  Press enter..." | ignore; return }
    let behind = (try { git -C $repo rev-list --count $"($bm)..origin/($bm)" | str trim | into int } catch { 0 })
    if $behind == 0 { print "  🌹 already up to date"; input "  Press enter..." | ignore; return }
    let r = (do { git -C $repo rebase $"origin/($bm)" } | complete)
    if $r.exit_code != 0 {
        git -C $repo rebase --abort | ignore
        print -e $"  🥀 rebase failed — run 'git rebase --abort' and resolve manually"
        return
    }
    let sync = (resolve-ahead-behind $repo $bm)
    print $"  🌹 synced — ↑($sync.ahead) ↓($sync.behind)"
    input "  Press enter..." | ignore
}

# ── rebase (interactive) ──────────────────────────────────────────────────────
def hub-rebase [repo: string, bm: string] {
    if ($bm | is-empty) { print "  🥀 cannot rebase during rebase/merge/etc"; input "  Press enter..." | ignore; return }
    print $"  current branch: ($bm)"
    let total = (try { git -C $repo rev-list --count $"origin/($bm)..($bm)" | str trim | into int } catch { 0 })
    if $total == 0 {
        print "  🌹 no local commits to rebase — already linear"
        input "  Press enter..." | ignore
        return
    }
    print $"  ($total) local commit\(s\) not yet on origin/($bm)"
    print -n "  how many to rebase? (default: $total): "
    let n_raw = (input "" | str trim)
    let n = if ($n_raw | is-empty) { $total } else { try { $n_raw | into int } catch { $total } }
    if $n < 1 { print "  🥀 need at least 1"; input "  Press enter..." | ignore; return }
    git -C $repo fetch origin | ignore
    print $"  🌹 rebasing last ($n) commit\(s\)..."
    let r = (do { git -C $repo rebase -i $"HEAD~($n)" } | complete)
    if $r.exit_code != 0 {
        print -e $"  🥀 rebase had conflicts — resolve then run 'git rebase --continue'"
    } else {
        print "  🌹 rebase complete — linear history updated"
    }
    input "  Press enter..." | ignore
}

# ── tags ──────────────────────────────────────────────────────────────────────
def hub-tags [repo: string] {
    loop {
        let lines = (try {
            git -C $repo tag --sort=-creatordate "--format=%(refname:short)\t%(committerdate:short)\t%(subject)"
            | lines | where { |l| $l | is-not-empty }
        } catch { [] })
        if ($lines | is-empty) {
            print "  🌹 no tags yet"
            print -n "  create first tag name: "
            let name = (input "" | str trim)
            if ($name | is-empty) { return }
            git -C $repo tag $name | ignore
            git -C $repo push origin $name | ignore
            print $"  🌹 created and pushed tag ($name)"
            input "  Press enter..." | ignore
            continue
        }

        let preview = $"git -C ($repo) show --color=always --stat {1}"
        let result = (fzf-run ($lines | str join "\n") [
            "--ansi"
            "--tabstop=1"
            "--delimiter=\t"
            "--prompt=  🌹 tags  "
            "--header=  enter=inspect  ctrl-n=new  ctrl-d=delete  ctrl-p=push all  esc=back"
            $"--preview=($preview)"
            "--preview-window=right:55%:wrap"
            "--expect=ctrl-d,ctrl-n,ctrl-p"
            "--bind=esc:abort"
        ])

        if ($result.stdout | is-empty) { return }

        let all_lines = ($result.stdout | lines)
        let key = ($all_lines | first | str trim)
        let selected = ($all_lines | skip 1 | str join "\n" | str trim)

        if $key == "ctrl-d" {
            let tag = ($selected | split row "\t" | get 0 | str trim)
            if ($tag | is-empty) { continue }
            print -n $"  delete tag ($tag) locally and on remote? [y/N] "
            let yn = (input "" | str trim | str downcase)
            if $yn == "y" {
                git -C $repo tag -d $tag | ignore
                git -C $repo push origin --delete refs/tags/$tag | ignore
                print $"  🌹 ($tag) deleted"
                input "  Press enter..." | ignore
            }
            continue
        }

        if $key == "ctrl-n" {
            print -n "  🌹 new tag name: "
            let name = (input "" | str trim)
            if ($name | is-empty) { continue }
            git -C $repo tag $name | ignore
            git -C $repo push origin $name | ignore
            print $"  🌹 created and pushed tag ($name)"
            input "  Press enter..." | ignore
            continue
        }

        if $key == "ctrl-p" {
            let r = (do { git -C $repo push origin --tags } | complete)
            if $r.exit_code == 0 {
                print "  🌹 all tags pushed to remote"
            } else {
                print -e $"  🥀 push failed: ($r.stderr)"
            }
            input "  Press enter..." | ignore
            continue
        }

        if $key == "enter" {
            let tag = ($selected | split row "\t" | get 0 | str trim)
            git -C $repo show --stat $tag | print
            input "  Press enter..." | ignore
        }
    }
}

# ── fix head ──────────────────────────────────────────────────────────────────
def hub-fix-head [repo: string] {
    let branch = (resolve-branch $repo)

    if ($branch | str starts-with "__rebase__") {
        print $"(ansi red_bold)  🥀 REBASE IN PROGRESS(ansi reset)"
        let choice = (["continue" "abort"] | input list --fuzzy "Rebase:")
        if $choice == "continue" {
            let r = (do { git -C $repo rebase --continue } | complete)
            if $r.exit_code != 0 { print -e $"  🥀 resolve conflicts first" }
        } else {
            git -C $repo rebase --abort | ignore
            print "  🌹 rebase aborted"
        }
        input "  Press enter..." | ignore
        return
    }
    if ($branch | str starts-with "__merge__") {
        print $"(ansi red_bold)  🥀 MERGE IN PROGRESS(ansi reset)"
        let choice = (["continue" "abort"] | input list --fuzzy "Merge:")
        if $choice == "continue" {
            let r = (do { git -C $repo merge --continue } | complete)
            if $r.exit_code != 0 { print -e "  🥀 resolve conflicts first" }
        } else {
            git -C $repo merge --abort | ignore
            print "  🌹 merge aborted"
        }
        input "  Press enter..." | ignore
        return
    }
    if ($branch | str starts-with "__cherry-pick__") {
        print $"(ansi red_bold)  🥀 CHERRY-PICK IN PROGRESS(ansi reset)"
        let choice = (["continue" "abort"] | input list --fuzzy "Cherry-pick:")
        if $choice == "continue" {
            git -C $repo cherry-pick --continue | ignore
        } else {
            git -C $repo cherry-pick --abort | ignore
            print "  🌹 cherry-pick aborted"
        }
        input "  Press enter..." | ignore
        return
    }
    if ($branch | str starts-with "__bisect__") {
        print $"(ansi red_bold)  🥀 BISECT IN PROGRESS(ansi reset)"
        git -C $repo bisect reset | ignore
        print "  🌹 bisect reset"
        input "  Press enter..." | ignore
        return
    }
    if ($branch | str starts-with "__detached__") {
        let hash = ($branch | str replace "__detached__" "")
        print $"(ansi red_bold)  🥀 DETACHED HEAD at ($hash)(ansi reset)"
        let nearby = (try {
            git -C $repo branch --contains HEAD | lines | where { |l| $l | is-not-empty }
            | each { |l| $l | str replace --regex '^\*?\s+' '' }
        } catch { [] })
        if not ($nearby | is-empty) {
            print $"  Branches containing this commit: ($nearby | str join ', ')"
        }
        let choice = (["create new branch here" "checkout existing branch" "abort"] | input list --fuzzy "Detached HEAD:")
        if $choice == "abort" { return }
        if ($choice | str starts-with "create") {
            print -n "  New branch name: "
            let name = (input "" | str trim)
            if ($name | is-empty) { return }
            let cb = (do { git -C $repo checkout -b $name } | complete)
            if $cb.exit_code != 0 { print -e $"  🥀 ($cb.stderr)" } else { print $"  🌹 switched to ($name)" }
            input "  Press enter..." | ignore
            return
        }
        if ($choice | str starts-with "checkout") {
            let branches = (list-branches $repo)
            if ($branches | is-empty) { print "  🥀 no branches"; return }
            let target = ($branches | input list --fuzzy "Switch to:")
            let co = (do { git -C $repo checkout $target } | complete)
            if $co.exit_code != 0 { print -e $"  🥀 ($co.stderr)" } else { print $"  🌹 switched to ($target)" }
            input "  Press enter..." | ignore
            return
        }
        return
    }

    # Clean HEAD — show reflog for navigation
    print $"  🌹 HEAD is clean on ($branch)"
    print ""
    git -C $repo reflog --oneline -10 | print
    print ""
    input "  Press enter..." | ignore
}

# =============================================================================
# SECTION 8 — INTERACTIVE HUB
# =============================================================================
def interactive-hub [repo: string, msg: string] {
    let branch  = (resolve-branch $repo)
    let sync    = (resolve-ahead-behind $repo $branch)
    let changed = (capture-changed $repo | length)
    let tags    = (try { git -C $repo tag | lines | length } catch { 0 })
    let head_tag = (try { git -C $repo tag --points-at HEAD | lines | first | str trim } catch { "" })
    let last_commit = (try { git -C $repo log -1 "--format=%h %s" --color=never | str trim } catch { "" })
    let stash_cnt = (try { git -C $repo stash list | lines | length } catch { 0 })
    let remote_url = (try { git -C $repo remote get-url origin | str trim | str replace --regex "^.*:" "" } catch { "" })
    let state   = if ($branch | str starts-with "__") { $"(ansi red_bold)⚠ ($branch)(ansi reset)" } else { $branch }

    # Display git information above the menu
    print -n "\e[2J\e[H"
    print $"(ansi red_bold)🌹 MANIFOLD(ansi reset)"
    print $"  (ansi red)🌹 Branch: ($state)(ansi reset)"
    print $"  (ansi red)🌹 Sync: ↑($sync.ahead) ↓($sync.behind)  Stash: ($stash_cnt)(ansi reset)"
    if ($last_commit | is-not-empty) { print $"  (ansi red)🌹 Commit: ($last_commit)(ansi reset)" }
    let tags_display = if ($head_tag | is-not-empty) { $head_tag } else { $tags | into string }
    print $"  (ansi red)🌹 Tags: ($tags_display)(ansi reset)"
    print $"  (ansi red)🌹 Changes: ($changed)(ansi reset)"
    if ($remote_url | is-not-empty) { print $"  (ansi red)🌹 Remote: ($remote_url)(ansi reset)" }
    print ""

      let options = [
          $"commit & push  \(($changed) changed\)  \(stage & submit all\)"
          "branches  (switch / create / delete)"
          "log  (view commit history)"
          "tags  (list / create / delete version markers)"
          "stash  (save & restore work in progress)"
          "diff  (review unstaged changes)"
          "rebase  (interactive — reorder/squash local commits)"
          "squash  (combine recent commits)"
          "amend  (edit last commit message & files)"
          "undo  (revert last action)"
          "sync  (fetch & rebase on remote — linear history)"
          "merge into  (merge current branch into selected)"
          "fix head  (repair detached or broken HEAD)"
      ] | str join "\n"

      let result = (fzf-run $options [
          "--ansi"
          "--prompt=  🌹 manifold  "
          $"--header=  ($state)  ↑($sync.ahead) ↓($sync.behind)  ($changed) changed"
          "--height=~20"
          "--bind=esc:abort"
      ])

      if $result.exit_code != 0 { return "abort" }
      let choice = ($result.stdout | str trim)
      if ($choice | is-empty) { return "" }
      if $choice == "abort" { return "abort" }
      $choice | split row " " | get 0
}

# ── merge current branch into selected target branch ──────────────────────────
def hub-merge-into [repo: string] {
    let current = (resolve-branch $repo)
    
    # Get all branches
    let branches = (try {
        git -C $repo branch -a | str trim | lines | each { |line|
            ($line | str replace -a "* " "" | str replace -a "  " "" | str trim)
        }
    } catch { [] })
    
    if ($branches | is-empty) {
        print "  🥀 No branches found"
        input "  Press enter..." | ignore
        return
    }
    
    # Filter out remote tracking branches (keep origin/xxx for reference) and current branch
    let local_branches = ($branches | where { |b| not ($b | str starts-with "remotes/") and $b != $current })
    
    if ($local_branches | is-empty) {
        print "  🥀 No other branches available to merge into"
        input "  Press enter..." | ignore
        return
    }
    
    let branches_str = ($local_branches | str join "\n")
    let target = (fzf-run $branches_str [
        "--ansi"
        "--prompt=  🌹 merge ($current) into  "
        "--header=select target branch"
        "--no-sort"
        "--height=~15"
    ]).stdout | str trim
    
    if ($target | is-empty) {
        print "  🥀 merge cancelled"
        return
    }
    
    print $"  🌹 fetching latest..."
    git -C $repo fetch origin | ignore

    # Stash any local changes before switching branches
    let has_changes = ((git -C $repo status --porcelain | str trim) | is-not-empty)
    if $has_changes {
        print "  🌹 stashing local changes..."
        let stash_ok = (do { git -C $repo stash push -m "auto-stash before merge" } | complete)
        if $stash_ok.exit_code != 0 {
            print -e $"  🥀 stash failed: ($stash_ok.stderr | str trim)"
            input "  Press enter..." | ignore
            return
        }
    }

    print $"  🌹 switching to ($target)..."
    let switch = (do { git -C $repo checkout $target } | complete)
    if $switch.exit_code != 0 {
        print -e $"  🥀 Failed to switch to ($target)"
        print -e $switch.stderr
        if $has_changes { do { git -C $repo stash pop } | complete | ignore }
        input "  Press enter..." | ignore
        return
    }

    print $"  🌹 merging ($current) into ($target)..."
    let merge = (do { git -C $repo merge $current } | complete)
    if $merge.exit_code == 0 {
        print $"  🌹 successfully merged ($current) into ($target)"
        let push = (do { git -C $repo push origin $target } | complete)
        if $push.exit_code == 0 {
            print $"  🌹 pushed ($target) to remote"
        } else {
            print -e $"  🥀 push failed: ($push.stderr)"
        }
    } else {
        print -e $"  🥀 merge failed: ($merge.stderr)"
    }

    # Switch back to original branch and restore stash
    print $"  🌹 switching back to ($current)..."
    git -C $repo checkout $current | ignore
    if $has_changes {
        print "  🌹 restoring stashed changes..."
        let pop_ok = (do { git -C $repo stash pop } | complete)
        if $pop_ok.exit_code != 0 {
            print -e $"  🥀 stash pop failed — run 'git stash drop' to clean up: ($pop_ok.stderr | str trim)"
        }
    }

    input "  Press enter..." | ignore
}

# =============================================================================
# SECTION 9 — MAIN
# =============================================================================
def ManifoldOS-Reshaping-History [msg: string = "update"] {
    $env.config.table.mode = "rounded"
    $env.config.table.index_mode = "always"

    let repo = (find-repo-root)
    if $repo == null {
        print $"(ansi red_bold)🌹 MANIFOLD(ansi reset)"
        let choice = (["bootstrap repo here" "abort"] | input list --fuzzy "No repo found:")
        if $choice == "abort" { return }
        if not (bootstrap-repo) { return }
        ManifoldOS-Reshaping-History $msg
        return
    }

    ensure-git-initialized $repo | ignore

    # ── Detached HEAD / mid-op: don't block, surface via hub ─────────────────
    let branch = (resolve-branch $repo)
    let bm = if ($branch | str starts-with "__") { $branch } else { $branch }

    let has_remote = (try { git -C $repo remote | str trim | is-not-empty } catch { false })
    if not $has_remote {
        let provider = (["GitHub" "GitLab" "manual URL"] | input list --fuzzy "Add remote:")
        let remote_url = if $provider == "GitHub" {
            let token = (get-github-token)
            if $token == null { return }
            github-create-repo ($repo | path basename) $token
        } else if $provider == "GitLab" {
            let token = (get-gitlab-token)
            if $token == null { return }
            gitlab-create-repo ($repo | path basename) $token
        } else { input "  Remote URL: " | str trim }
        if ($remote_url | is-empty) or $remote_url == null { return }
        let ra = (do { git -C $repo remote add origin $remote_url } | complete)
        if $ra.exit_code != 0 { render-failure "REMOTE" $ra.stderr; return }
    }

    if (check-remote-reachable $repo) { return }

     # ── Hub loop ──────────────────────────────────────────────────────────────
     loop {
         let action = (interactive-hub $repo $msg)

         if $action == "abort" { print -n "\e[2J\e[H"; return }
         if ($action | is-empty) { continue }

         let current_bm = (resolve-branch $repo)
         let safe_bm = if ($current_bm | str starts-with "__") { "" } else { $current_bm }

         match $action {
             "commit"   => { hub-commit-push $repo $safe_bm $msg; return }
             "branches" => { 
                 hub-branches $repo
                 print -n "\e[2J\e[H"
             }
             "log"      => { hub-log $repo }
             "tags"     => { hub-tags $repo }
             "stash"    => { hub-stash $repo }
             "diff"     => { hub-diff $repo }
             "rebase"   => { hub-rebase $repo $safe_bm }
             "squash"   => { hub-squash $repo $safe_bm }
             "amend"    => { hub-amend $repo }
             "undo"     => { hub-undo $repo }
             "sync"     => { hub-sync $repo $safe_bm }
             "merge"    => { hub-merge-into $repo }
             "fix"      => { hub-fix-head $repo }
             _          => { }
         }
     }
}

# =============================================================================
# SECTION 10 — CONVENIENCE COMMANDS (still available standalone)
# =============================================================================
def git-undo []            { let r = (find-repo-root); if $r == null { return }; hub-undo $r }
def git-amend []           { let r = (find-repo-root); if $r == null { return }; hub-amend $r }
def git-log []             { let r = (find-repo-root); if $r == null { return }; hub-log $r }
def git-reflog []          {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo"; return }
    git -C $repo reflog --oneline -20
}
def git-branch [name: string] {
    let repo = (find-repo-root)
    if $repo == null { return }
    let r = (do { git -C $repo checkout -b $name } | complete)
    if $r.exit_code != 0 { print -e $"  🥀 ($r.stderr)" } else { print $"  🌹 switched to ($name)" }
}
def git-tag [name: string] {
    let repo = (find-repo-root)
    if $repo == null { return }
    git -C $repo tag $name | ignore
    git -C $repo push origin $name | ignore
    print $"  🌹 tag ($name) pushed"
}
def git-squash [n: int = 2] {
    let repo = (find-repo-root)
    if $repo == null { return }
    hub-squash $repo (resolve-branch $repo)
}
def git-stats-json [] {
    let repo = (find-repo-root)
    if $repo == null { return }
    let branch = (resolve-branch $repo)
    let is_real = (not ($branch | str starts-with "__")) and ($branch | is-not-empty)
    let sync = if $is_real { resolve-ahead-behind $repo $branch } else { { ahead: 0 behind: 0 } }
    {
        branch:     $branch
        remote_url: (try { git -C $repo remote get-url origin | str trim } catch { "none" })
        total:      (try { git -C $repo rev-list --count HEAD | str trim } catch { "?" })
        last_push:  (try { git -C $repo log -1 "--format=%ad" --date=relative | str trim } catch { "?" })
        ahead:      $sync.ahead
        behind:     $sync.behind
    } | to json
}

# =============================================================================
# SECTION 11 — KEYBINDINGS
# =============================================================================
$env.config.keybindings = ($env.config.keybindings | append [
    {
        name: ManifoldOS_Reshaping_History
        modifier: control
        keycode: char_g
        mode: [emacs, vi_insert, vi_normal]
        event: { send: executehostcommand cmd: "ManifoldOS-Reshaping-History" }
    }
])