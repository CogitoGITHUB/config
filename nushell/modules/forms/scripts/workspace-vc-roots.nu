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
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // GITHUB TOKEN SETUP 🌹(ansi reset)"
    print $"(ansi grey)  One-time setup. Saved to ~/.secrets/github_token \(never committed\).(ansi reset)"
    print ""
    print "   1. Browser will open → https://github.com/settings/tokens/new"
    print "   2. Set note: ManifoldOS"
    print "   3. Set expiration"
    print "   4. Check 'repo' scope"
    print "   5. Click 'Generate token' and copy it"
    print ""
    try { xdg-open "https://github.com/settings/tokens/new?scopes=repo&description=ManifoldOS" } catch {
        print "  https://github.com/settings/tokens/new?scopes=repo&description=ManifoldOS"
    }
    let token = (input "  Paste token: " | str trim)
    if ($token | is-empty) { return null }
    $token | save -f $token_path
    chmod 600 $token_path
    print $"(ansi green)  ✓ saved to ~/.secrets/github_token(ansi reset)"
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
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // GITLAB TOKEN SETUP 🌹(ansi reset)"
    print $"(ansi grey)  One-time setup. Saved to ~/.secrets/gitlab_token \(never committed\).(ansi reset)"
    print ""
    print "   1. Browser will open → https://gitlab.com/-/profile/personal_access_tokens"
    print "   2. Set name: ManifoldOS"
    print "   3. Set expiration"
    print "   4. Check 'api' scope"
    print "   5. Click 'Create personal access token' and copy it"
    print ""
    try { xdg-open "https://gitlab.com/-/profile/personal_access_tokens?name=ManifoldOS&scopes=api" } catch {
        print "  https://gitlab.com/-/profile/personal_access_tokens?name=ManifoldOS&scopes=api"
    }
    let token = (input "  Paste token: " | str trim)
    if ($token | is-empty) { return null }
    $token | save -f $token_path
    chmod 600 $token_path
    print $"(ansi green)  ✓ saved to ~/.secrets/gitlab_token(ansi reset)"
    $token
}

def github-create-repo [name: string, token: string] {
    let body = ({ name: $name, private: false, auto_init: false } | to json)
    let gh_headers = { Authorization: $"Bearer ($token)", "User-Agent": $config.author_name, Accept: "application/vnd.github+json" }
    let resp = (try {
        http post --content-type "application/json" --full --allow-errors --headers $gh_headers "https://api.github.com/user/repos" $body
    } catch { |err| print -e $"(ansi red_bold)  ✗ GitHub API failed:(ansi reset) ($err.msg)"; return null })
    if $resp.status == 201 {
        $resp.body.ssh_url
    } else if $resp.status == 422 {
        print $"(ansi yellow)  ⚠ repo already exists — fetching SSH url(ansi reset)"
        try {
            let get_resp = (http get --full --allow-errors --headers $gh_headers $"https://api.github.com/repos/($config.github_user)/($name)")
            $get_resp.body.ssh_url
        } catch { |err| print -e $"(ansi red_bold)  ✗ fetch existing repo failed:(ansi reset) ($err.msg)"; null }
    } else {
        print -e $"(ansi red_bold)  ✗ GitHub API ($resp.status):(ansi reset) ($resp.body | to json)"
        null
    }
}

def gitlab-create-repo [name: string, token: string] {
    let body = ({ name: $name, visibility: "public", initialize_with_readme: false } | to json)
    try {
        let gl_headers = { "PRIVATE-TOKEN": $token, "User-Agent": $config.author_name }
        let resp = (http post --content-type "application/json" --full --allow-errors --headers $gl_headers "https://gitlab.com/api/v4/projects" $body)
        if $resp.status == 201 { $resp.body.ssh_url_to_repo } else {
            print -e $"(ansi red_bold)  ✗ GitLab API ($resp.status):(ansi reset) ($resp.body | to json)"
            null
        }
    } catch { |err|
        print -e $"(ansi red_bold)  ✗ GitLab API failed:(ansi reset) ($err.msg)"
        null
    }
}

def ensure-ssh-key [] {
    let key_path = ($env.HOME | path join ".ssh" "id_ed25519")
    let pub_path = $"($key_path).pub"
    if not ($key_path | path exists) {
        print $"(ansi yellow)  ⚙ generating SSH key...(ansi reset)"
        let r = (do { ssh-keygen -t ed25519 -C $config.author_email -f $key_path -N "" } | complete)
        if $r.exit_code != 0 { print -e $"(ansi red_bold)  ✗ ssh-keygen failed:(ansi reset) ($r.stderr)"; return false }
        print $"(ansi green)  ✓ key generated(ansi reset)"
    }
    let test = (do { ssh -T git@github.com -o StrictHostKeyChecking=accept-new -o BatchMode=yes } | complete)
    let authed = ($test.stderr | str contains "successfully authenticated") or ($test.stdout | str contains "successfully authenticated")
    if $authed { print $"(ansi green)  ✓ SSH auth ok(ansi reset)"; return true }
    let pub = (open $pub_path | str trim)
    print ""
    print $"(ansi red_bold)  ── SSH PUBLIC KEY ──────────────────────────────────────────(ansi reset)"
    print $"  ($pub)"
    print $"(ansi red_bold)  ────────────────────────────────────────────────────────────(ansi reset)"
    print ""
    print $"(ansi yellow)  1. Copy the key above(ansi reset)"
    print $"(ansi yellow)  2. Go to → https://github.com/settings/ssh/new(ansi reset)"
    print $"(ansi yellow)  3. Paste it and click Save(ansi reset)"
    print ""
    try { xdg-open "https://github.com/settings/ssh/new" } catch { }
    input "  Press Enter once you've saved the key on GitHub... " | ignore
    let test2 = (do { ssh -T git@github.com -o StrictHostKeyChecking=accept-new } | complete)
    let ok = ($test2.stderr | str contains "successfully authenticated") or ($test2.stdout | str contains "successfully authenticated")
    if not $ok { print $"(ansi yellow)  ⚠ could not verify — continuing anyway(ansi reset)" } else { print $"(ansi green)  ✓ SSH auth confirmed(ansi reset)" }
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
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  No git repo found — bootstrapping ($repo_name).(ansi reset)"
    print ""
    let provider = (["GitHub" "GitLab"] | input list --fuzzy "Push to:")
    let token = if $provider == "GitHub" { get-github-token } else { get-gitlab-token }
    if $token == null { print -e "  ✗ no token — aborting"; return false }
    print $"(ansi yellow)  ⚙ creating ($provider) repo ($repo_name)...(ansi reset)"
    let remote_url = if $provider == "GitHub" {
        github-create-repo $repo_name $token
    } else {
        gitlab-create-repo $repo_name $token
    }
    if $remote_url == null { return false }
    print $"(ansi green)  ✓ repo created → ($remote_url)(ansi reset)"
    let gi = (do { git init $repo } | complete)
    if $gi.exit_code != 0 { print -e $"(ansi red_bold)  ✗ git init failed:(ansi reset) ($gi.stderr)"; return false }
    print $"(ansi green)  ✓ git init(ansi reset)"
    git -C $repo config user.name  $config.author_name
    git -C $repo config user.email $config.author_email
    print $"(ansi green)  ✓ identity set(ansi reset)"
    let ra = (do { git -C $repo remote add origin $remote_url } | complete)
    if $ra.exit_code != 0 { print -e $"(ansi red_bold)  ✗ remote add failed:(ansi reset) ($ra.stderr)"; return false }
    print $"(ansi green)  ✓ remote → ($remote_url)(ansi reset)"
    let bm = $config.default_branch
    let cb = (do { git -C $repo checkout -b $bm } | complete)
    if $cb.exit_code != 0 { print -e $"(ansi red_bold)  ✗ branch create failed:(ansi reset) ($cb.stderr)"; return false }
    let needs_file = (try { (git -C $repo status --short | str trim | is-empty) } catch { true })
    if $needs_file { ".gitkeep" | save -f ($repo | path join ".gitkeep") }
    git -C $repo add -A | ignore
    let ts = (date now | format date "%Y-%m-%d %H:%M")
    let ci = (do { git -C $repo commit -m $"[($bm)] init ($ts)" --author $"($config.author_name) <($config.author_email)>" } | complete)
    if $ci.exit_code != 0 { print -e $"(ansi red_bold)  ✗ initial commit failed:(ansi reset) ($ci.stderr)"; return false }
    print $"(ansi green)  ✓ initial commit(ansi reset)"
    if ($remote_url | str starts-with "git@") or ($remote_url | str starts-with "ssh://") {
        let ssh_ok = (ensure-ssh-key)
        if not $ssh_ok { return false }
    }
    let pr = (do { git -C $repo push -u origin $bm } | complete)
    if $pr.exit_code != 0 {
        let pr2 = (do { git -C $repo push -u origin $bm } | complete)
        if $pr2.exit_code != 0 { print -e $"(ansi red_bold)  ✗ push failed:(ansi reset) ($pr2.stderr)"; return false }
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
    let ahead  = (try { git -C $repo rev-list --count $"origin/($branch)..($branch)"  | str trim | into int } catch { 0 })
    let behind = (try { git -C $repo rev-list --count $"($branch)..origin/($branch)"  | str trim | into int } catch { 0 })
    { ahead: $ahead  behind: $behind }
}

def fetch-commits-from [repo: string, n: int] {
    try {
        git -C $repo log "--format=%h%x1e%ad%x1e%s%x1e%an" --date=relative $"--max-count=($n)"
        | lines | where { |l| $l | is-not-empty }
        | each { |line|
            let p = ($line | split row $SEP)
            { commit: ($p | get 0)  age: ($p | get 1)  subject: ($p | get 2)  author: ($p | get 3) }
        }
    } catch { [] }
}

def capture-changed [repo: string] {
    try {
        let raw = (do { git -C $repo status --porcelain=v1 -z } | complete)
        if $raw.exit_code != 0 { return [] }
        let tokens = ($raw.stdout | split row "\u{0000}" | where { |t| $t | is-not-empty })
        mut results = []
        mut i = 0
        while $i < ($tokens | length) {
            let tok = ($tokens | get $i)
            let x     = ($tok | str substring 0..0)
            let y     = ($tok | str substring 1..1)
            let fname = ($tok | str substring 3..)
            let code  = if $x != " " and $x != "?" { $x } else { $y }
            let status = match $code {
                "A" => "added"
                "D" => "deleted"
                "M" => "modified"
                "R" => "renamed"
                "C" => "copied"
                "U" => "unmerged"
                "?" => "untracked"
                _   => "changed"
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
        print ""
        print $"(ansi red_bold)  🥀 REMOTE UNREACHABLE — cannot reach ($host) via SSH(ansi reset)"
        print $"(ansi grey)  check network / VPN or run: ssh -T git@($host)(ansi reset)"
        print ""
        true
    } else { false }
}

def check-divergence [repo: string, branch: string] {
    if ($branch | is-empty) { return false }
    if not (remote-branch-exists $repo $branch) { return false }
    let ahead  = (try { git -C $repo rev-list --count $"origin/($branch)..($branch)" | str trim | into int } catch { 0 })
    let behind = (try { git -C $repo rev-list --count $"($branch)..origin/($branch)" | str trim | into int } catch { 0 })
    if $ahead == 0 or $behind == 0 { return false }
    print ""
    print $"(ansi red_bold)  🥀 DIVERGED HISTORY — ($branch) has diverged from remote(ansi reset)"
    print $"  local is ($ahead) ahead, ($behind) behind origin/($branch)"
    print ""
    let choice = (["rebase onto remote" "abort"] | input list --fuzzy "Divergence strategy:")
    if $choice == "abort" { return true }
    let r = (do { git -C $repo rebase $"origin/($branch)" } | complete)
    if $r.exit_code != 0 {
        git -C $repo rebase --abort | ignore
        print -e $"(ansi red_bold)  🥀 rebase failed — aborted(ansi reset)"
        return true
    }
    git -C $repo fetch origin | ignore
    print $"(ansi green)  🌹 rebased onto remote ($branch)(ansi reset)"
    false
}

def check-behind [repo: string, branch: string] {
    if ($branch | is-empty) { return false }
    if not (remote-branch-exists $repo $branch) { return false }
    let behind = (try {
        git -C $repo rev-list --count $"($branch)..origin/($branch)" | str trim | into int
    } catch { 0 })
    if $behind == 0 { return false }
    let remote_commits = (try {
        git -C $repo log "--format=%h%x1e%ad%x1e%s" --date=relative $"($branch)..origin/($branch)"
        | lines | where { |l| $l | is-not-empty }
        | each { |line|
            let p = ($line | split row $SEP)
            { commit: ($p | get 0)  age: ($p | get 1)  subject: ($p | get 2) }
        }
    } catch { [] })
    print ""
    print $"(ansi red_bold)  🥀 BEHIND REMOTE — ($branch) is ($behind) commit(s) behind(ansi reset)"
    $remote_commits | print
    print ""
    let choice = (
        [
            "fast-forward  — rebase local commits on top of remote (recommended)"
            "pull only     — move branch to remote tip, discard local"
            "abort         — exit and handle manually"
        ] | input list --fuzzy "Behind remote — how to proceed?"
    )
    if ($choice | str starts-with "abort") { return true }
    if ($choice | str starts-with "fast-forward") {
        let local_only = (try {
            git -C $repo rev-list --count $"origin/($branch)..($branch)" | str trim | into int
        } catch { 0 })
        if $local_only == 0 {
            let r = (do { git -C $repo merge --ff-only $"origin/($branch)" } | complete)
            if $r.exit_code != 0 { print -e $"(ansi red_bold)  🥀 fast-forward failed:(ansi reset) ($r.stderr)"; return true }
            print $"(ansi green)  🌹 fast-forwarded to remote tip(ansi reset)"
        } else {
            let r = (do { git -C $repo rebase $"origin/($branch)" } | complete)
            if $r.exit_code != 0 {
                git -C $repo rebase --abort | ignore
                print -e $"(ansi red_bold)  🥀 rebase failed — aborted(ansi reset)"
                return true
            }
            print $"(ansi green)  🌹 local commits rebased onto remote tip(ansi reset)"
        }
        git -C $repo fetch origin | ignore
        return false
    }
    if ($choice | str starts-with "pull only") {
        let local_only = (try {
            git -C $repo rev-list --count $"origin/($branch)..($branch)" | str trim | into int
        } catch { 0 })
        if $local_only > 0 {
            print $"(ansi yellow)  🥀 discarding ($local_only) local-only commit(s)(ansi reset)"
            let confirm = (["yes — discard them" "no — abort"] | input list --fuzzy "Discard local commits?")
            if not ($confirm | str starts-with "yes") { return true }
        }
        let r = (do { git -C $repo reset --hard $"origin/($branch)" } | complete)
        if $r.exit_code != 0 { print -e $"(ansi red_bold)  🥀 reset failed:(ansi reset) ($r.stderr)"; return true }
        git -C $repo fetch origin | ignore
        print $"(ansi green)  🌹 pulled — branch now at remote tip(ansi reset)"
        return false
    }
    true
}

def check-conflicts [repo: string] {
    let conflicted = (try {
        git -C $repo diff --name-only --diff-filter=U
        | lines | where { |l| $l | is-not-empty }
    } catch { [] })
    if not ($conflicted | is-empty) {
        print ""
        print $"(ansi red_bold)  🥀 UNRESOLVED CONFLICTS — resolve before committing(ansi reset)"
        $conflicted | print
        print ""
        ["abort"] | input list --fuzzy "Conflicts detected — resolve manually then re-run:" | ignore
        return true
    }
    false
}

def check-large-files [repo: string] {
    # Express limit as filesize so it's comparable to ls .size directly
    let limit = ($config.max_file_size_mb * 1mb)
    let large = (try {
        git -C $repo status --porcelain=v1 -z
        | split row "\u{0000}"
        | where { |t| $t | is-not-empty }
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
        print ""
        print $"(ansi red_bold)  🥀 LARGE FILES — ($config.max_file_size_mb)MB limit exceeded(ansi reset)"
        $large | print
        print ""
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Large files — proceed?")
        $choice == "abort"
    } else { false }
}

def check-stash [repo: string] {
    let count = (try { git -C $repo stash list | lines | length } catch { 0 })
    if $count > 0 {
        let stashes = (git -C $repo stash list | lines)
        print ""
        print $"(ansi red_bold)  🥀 STASHED CHANGES — ($count) stash(es) detected(ansi reset)"
        $stashes | print
        print ""
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Stash detected — proceed?")
        $choice == "abort"
    } else { false }
}

def check-gitignore [repo: string] {
    let danger_patterns = [
        ".env" ".env.local" ".env.*"
        "*.pem" "*.key" "*.p12" "*.pfx" "*.cer"
        "id_rsa" "id_ed25519" "id_ecdsa"
        "node_modules" "__pycache__" "*.pyc"
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
        print ""
        print $"(ansi red_bold)  🥀 SUSPICIOUS FILES — these look like secrets or build artifacts(ansi reset)"
        $suspicious | print
        print $"(ansi grey)  consider adding them to .gitignore(ansi reset)"
        print ""
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Suspicious files — proceed?")
        $choice == "abort"
    } else { false }
}

# =============================================================================
# SECTION 4 — PUSH HELPER
# =============================================================================
def do-push [repo: string, branch: string] {
    let r = (do { git -C $repo push --set-upstream origin $branch } | complete)
    $r
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
    print $"(ansi red_bold)  ($rose) ($commit_msg)(ansi reset)"
    print ""
    for f in $changed {
        let symbol = match $f.status { "deleted" => $wilt _ => $rose }
        print $"  ($symbol) ($f.status)  ($f.file)"
    }
    print ""
    let total   = ($changed | length)
    let deleted = ($changed | where status == "deleted" | length)
    let health  = if $total == 0 {
        "nothing changed"
    } else if $deleted == $total {
        $"($wilt)($wilt)($wilt)  everything was lost"
    } else if $deleted > ($total / 2 | math floor) {
        $"($rose)($wilt)($wilt)  the history shifts — some things did not survive"
    } else {
        $"($rose)($rose)($rose)($rose)($rose)  the history has been reshaped"
    }
    print $"  ($health)"
    print ""
}

def render-failure [stage: string, reason: string] {
    print ""
    print $"(ansi red_bold)  🥀 ($stage) FAILED(ansi reset)"
    print $"(ansi grey)  ($reason)(ansi reset)"
    print ""
}

# =============================================================================
# SECTION 6 — INTERACTIVE HUB
# =============================================================================

# Build a branch line for fzf display:
# "* master  ↑2 ↓0  abc1234  3 hours ago  fix login bug"
def branch-fzf-lines [repo: string] {
    try {
        git -C $repo branch
        | lines
        | where { |l| $l | is-not-empty }
        | each { |l|
            let is_current = ($l | str starts-with "*")
            let name = ($l | str replace --regex '^\*?\s+' '' | str trim)
            let marker = if $is_current { $"(ansi green_bold)*" } else { " " }
            let sync = (resolve-ahead-behind $repo $name)
            let ab = $"↑($sync.ahead) ↓($sync.behind)"
            let last = (try {
                git -C $repo log -1 "--format=%h  %ar  %s" $name | str trim
            } catch { "no commits" })
            $"($marker) ($name)  ($ab)  ($last)(ansi reset)"
        }
    } catch { [] }
}

# Run fzf via run-external to avoid Nu's = operator parse ambiguity.
# All fzf flags are passed as a list — no quoting issues.
def fzf-run [input_str: string, args: list<string>] {
    let tmp = (mktemp)
    $input_str | save -f $tmp
    let result = (do { run-external "sh" "-c" $"cat ($tmp) | fzf ($args | str join ' ')" } | complete)
    rm -f $tmp
    $result
}

# fzf branch picker — enter=switch, ctrl-n=new, ctrl-d=delete
def interactive-branches [repo: string] {
    let sentinel = ($env.HOME | path join ".manifold_action")

    loop {
        let lines = (branch-fzf-lines $repo | str join "\n")
        if ($lines | str trim | is-empty) {
            print "  🥀 no branches found"
            return
        }

        # preview command: extract branch name (2nd token) and show log
        let preview_cmd = $"git -C ($repo) log --oneline --color=always -12 {2}"
        let bind_new    = $"ctrl-n:execute(echo __new__ > ($sentinel))+abort"
        let bind_del    = $"ctrl-d:execute(echo __delete__:{2} > ($sentinel))+abort"
        let bind_esc    = "esc:abort"

        let result = (fzf-run $lines [
            "--ansi"
            "--prompt=  🌹 branch  "
            "--header=  enter=switch  ctrl-n=new  ctrl-d=delete  esc=back"
            $"--preview=($preview_cmd)"
            "--preview-window=right:45%:wrap"
            $"--bind=($bind_new)"
            $"--bind=($bind_del)"
            $"--bind=($bind_esc)"
        ])

        # Read sentinel written by fzf --bind execute()
        let action_raw = (
            if ($sentinel | path exists) {
                let v = (open $sentinel | str trim)
                rm -f $sentinel
                $v
            } else { "" }
        )

        # ── ctrl-d: delete branch ───────────────────────────────────────────
        if ($action_raw | str starts-with "__delete__") {
            let target = ($action_raw | str replace "__delete__:" "" | str trim)
            let current = (resolve-branch $repo)
            if $target == $current {
                print $"  🥀 cannot delete the currently checked-out branch ($target)"
                input "  Press enter to continue..." | ignore
                continue
            }
            let unpushed = (try {
                git -C $repo rev-list --count $"origin/($target)..($target)" | str trim | into int
            } catch { 0 })
            let confirm_msg = if $unpushed > 0 {
                $"  ⚠ ($target) has ($unpushed) unpushed commit(s) — delete anyway? [y/N] "
            } else {
                $"  delete ($target)? [y/N] "
            }
            print -n $confirm_msg
            let yn = (input "" | str trim | str downcase)
            if $yn == "y" {
                let rd = (do { git -C $repo branch -D $target } | complete)
                if $rd.exit_code != 0 {
                    print -e $"  🥀 delete failed: ($rd.stderr)"
                } else {
                    if (remote-branch-exists $repo $target) {
                        let rdr = (do { git -C $repo push origin --delete $target } | complete)
                        if $rdr.exit_code != 0 {
                            print $"  🌹 local deleted — remote delete failed: ($rdr.stderr)"
                        } else {
                            print $"  🌹 ($target) deleted locally and on remote"
                        }
                    } else {
                        print $"  🌹 ($target) deleted locally"
                    }
                }
                input "  Press enter to continue..." | ignore
            }
            continue
        }

        # ── ctrl-n: new branch ──────────────────────────────────────────────
        if ($action_raw == "__new__") {
            print -n "  🌹 new branch name: "
            let new_name = (input "" | str trim)
            if ($new_name | is-empty) {
                print "  🥀 no name — cancelled"
                input "  Press enter to continue..." | ignore
                continue
            }
            let cb = (do { git -C $repo checkout -b $new_name } | complete)
            if $cb.exit_code != 0 {
                print -e $"  🥀 branch create failed: ($cb.stderr)"
                input "  Press enter to continue..." | ignore
            } else {
                print $"  🌹 switched to ($new_name)"
                input "  Press enter to continue..." | ignore
            }
            continue
        }

        # ── enter: switch branch ────────────────────────────────────────────
        if $result.exit_code == 0 {
            let chosen = ($result.stdout | str trim)
            if ($chosen | is-empty) { return }
            # line format: "* name  ↑0 ↓0  ..." — name is always the 2nd token
            let target = ($chosen | split row " " | where { |t| $t | is-not-empty } | get 1)
            let current = (resolve-branch $repo)
            if $target == $current {
                print $"  🌹 already on ($target)"
                input "  Press enter..." | ignore
                continue
            }
            let co = (do { git -C $repo checkout $target } | complete)
            if $co.exit_code != 0 {
                print -e $"  🥀 checkout failed: ($co.stderr)"
                input "  Press enter to continue..." | ignore
            } else {
                print $"  🌹 switched to ($target)"
                return
            }
            continue
        }

        # esc / abort — exit picker
        return
    }
}

# Top-level interactive hub
def interactive-hub [repo: string] {
    print -n "\e[2J\e[H"
    let branch  = (resolve-branch $repo)
    let sync    = (resolve-ahead-behind $repo $branch)
    let changed = (capture-changed $repo | length)

    let options = [
        $"commit & push  \(($changed) changed\)"
        "branches"
        "abort"
    ] | str join "\n"

    let header  = $"  ($branch)  ↑($sync.ahead) ↓($sync.behind)"

    let result = (fzf-run $options [
        "--ansi"
        "--prompt=  🌹 manifold  "
        $"--header=($header)"
        "--no-sort"
        "--height=~10"
    ])

    let choice = ($result.stdout | str trim)
    if ($choice | is-empty) or ($choice == "abort") { return "abort" }
    if ($choice | str starts-with "commit") { return "commit" }
    if $choice == "branches" { return "branches" }
    "abort"
}

# =============================================================================
# SECTION 7 — ENTRY POINT PROMPT (enter=fast, space=interactive)
# =============================================================================
def manifold-entry-prompt [repo: string, branch: string] {
    let changed = (capture-changed $repo | length)
    let sync    = (resolve-ahead-behind $repo $branch)
    print ""
    print $"(ansi red_bold)  🌹 ($branch)  ↑($sync.ahead) ↓($sync.behind)  ($changed) changed(ansi reset)"
    print $"(ansi grey)     enter = fast commit·push   space = interactive   esc/q = abort(ansi reset)"
    print ""

    # input listen key event record shape (all codes are lowercase strings):
    #   { type: "key"  key_type: "other"  code: "enter"   modifiers: [] }
    #   { type: "key"  key_type: "char"   code: " "       modifiers: [] }
    #   { type: "key"  key_type: "other"  code: "escape"  modifiers: [] }
    #   { type: "key"  key_type: "char"   code: "q"       modifiers: [] }
    #   { type: "key"  key_type: "char"   code: "c"       modifiers: ["control"] }
    mut result = "abort"
    loop {
        let key = (input listen --types [key])
        let code     = ($key.code?     | default "" | str downcase)
        let key_type = ($key.key_type? | default "")
        let mods     = ($key.modifiers? | default [])

        # Ctrl-C — hard abort
        if $code == "c" and ("control" in $mods) {
            $result = "abort"
            break
        }

        $result = match [$key_type $code] {
            ["other" "enter"]  => "fast"
            ["char"  " "]      => "interactive"
            ["other" "escape"] => "abort"
            ["char"  "q"]      => "abort"
            _                  => "retry"
        }

        if $result != "retry" { break }
    }
    $result
}

# =============================================================================
# SECTION 8 — SHARED COMMIT/PUSH FLOW
# =============================================================================
def run-commit-push [repo: string, bm: string, msg: string] {
    # Safety checks (remote reachability already done before calling this)
    let fetch_result = (do { git -C $repo fetch origin } | complete)
    if $fetch_result.exit_code != 0 { render-failure "FETCH" $fetch_result.stderr; return }

    if (check-divergence $repo $bm)   { return }
    if (check-behind $repo $bm)       { return }
    if (check-conflicts $repo)        { return }
    if (check-stash $repo)            { return }
    if (check-large-files $repo)      { return }
    if (check-gitignore $repo)        { return }

    let changed = (capture-changed $repo)
    if ($changed | is-empty) {
        print ""
        print $"  🌹 ($bm)  nothing to reshape"
        print ""
        return
    }

    let commit_msg = if ($msg == "update") {
        let ts = (date now | format date "%Y-%m-%d %H:%M")
        $"[($bm)] ($ts)"
    } else { $msg }

    let author = $"($config.author_name) <($config.author_email)>"
    git -C $repo add -A | ignore
    let commit_result = (do { git -C $repo commit -m $commit_msg --author $author } | complete)
    if $commit_result.exit_code != 0 { render-failure "COMMIT" $commit_result.stderr; return }

    let push_result = (do-push $repo $bm)
    if $push_result.exit_code != 0 { render-failure "PUSH" $push_result.stderr; return }

    try { git -C $repo fetch origin } catch { }
    let sync    = (resolve-ahead-behind $repo $bm)
    let elapsed = "done"

    render-summary $bm $changed $commit_msg $sync $elapsed
}

# =============================================================================
# SECTION 9 — MAIN
# =============================================================================
def ManifoldOS-Reshaping-History [msg: string = "update"] {
    $env.config.table.mode = "rounded"
    $env.config.table.index_mode = "always"

    let repo = (find-repo-root)
    if $repo == null {
        print ""
        print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
        print $"(ansi grey)  No git repo found in ($env.PWD) or any parent.(ansi reset)"
        print ""
        let choice = (["bootstrap repo here" "abort"] | input list --fuzzy "No repo found — bootstrap from dir name?")
        if $choice == "abort" { return }
        let ok = (bootstrap-repo)
        if not $ok { return }
        ManifoldOS-Reshaping-History $msg
        return
    }

    let init_ok = (ensure-git-initialized $repo)
    if not $init_ok { return }

    # ── Detached HEAD / mid-operation guard ──────────────────────────────────
    let branch = (resolve-branch $repo)

    if ($branch | str starts-with "__rebase__") {
        print $"(ansi red_bold)  🥀 REBASE IN PROGRESS — finish or abort it first(ansi reset)"
        print $"(ansi grey)  git rebase --continue  |  git rebase --abort(ansi reset)"
        return
    }
    if ($branch | str starts-with "__merge__") {
        print $"(ansi red_bold)  🥀 MERGE IN PROGRESS — finish or abort it first(ansi reset)"
        print $"(ansi grey)  git merge --continue  |  git merge --abort(ansi reset)"
        return
    }
    if ($branch | str starts-with "__cherry-pick__") {
        print $"(ansi red_bold)  🥀 CHERRY-PICK IN PROGRESS — finish or abort it first(ansi reset)"
        print $"(ansi grey)  git cherry-pick --continue  |  git cherry-pick --abort(ansi reset)"
        return
    }
    if ($branch | str starts-with "__bisect__") {
        print $"(ansi red_bold)  🥀 BISECT IN PROGRESS — finish it first(ansi reset)"
        print $"(ansi grey)  git bisect reset(ansi reset)"
        return
    }
    if ($branch | str starts-with "__detached__") {
        let hash = ($branch | str replace "__detached__" "")
        print ""
        print $"(ansi red_bold)  🥀 DETACHED HEAD at ($hash)(ansi reset)"
        print $"(ansi grey)  You're not on any branch.(ansi reset)"
        print ""
        let nearby = (try {
            git -C $repo branch --contains HEAD | lines | where { |l| $l | is-not-empty } | each { |l| $l | str replace --regex '^\*?\s+' '' }
        } catch { [] })
        if not ($nearby | is-empty) {
            print $"(ansi grey)  Branches containing this commit:(ansi reset)"
            $nearby | each { |b| print $"    ($b)" } | ignore
            print ""
        }
        let choice = (["create new branch from here" "checkout existing branch" "abort"] | input list --fuzzy "Detached HEAD — what to do?")
        if $choice == "abort" { return }
        if ($choice | str starts-with "create") {
            let new_name = (input "  New branch name: " | str trim)
            if ($new_name | is-empty) { print -e "  🥀 no name given"; return }
            let cb = (do { git -C $repo checkout -b $new_name } | complete)
            if $cb.exit_code != 0 { print -e $"  🥀 branch create failed: ($cb.stderr)"; return }
            print $"(ansi green)  🌹 switched to new branch ($new_name)(ansi reset)"
            ManifoldOS-Reshaping-History $msg
            return
        }
        if ($choice | str starts-with "checkout") {
            let branches = (list-branches $repo)
            if ($branches | is-empty) { print -e "  🥀 no branches found"; return }
            let target = ($branches | input list --fuzzy "Switch to branch:")
            let co = (do { git -C $repo checkout $target } | complete)
            if $co.exit_code != 0 { print -e $"  🥀 checkout failed: ($co.stderr)"; return }
            print $"(ansi green)  🌹 switched to ($target)(ansi reset)"
            ManifoldOS-Reshaping-History $msg
            return
        }
        return
    }

    # bm is now a real branch name
    let bm = $branch

    let has_remote = (try { git -C $repo remote | str trim | is-not-empty } catch { false })
    if not $has_remote {
        print $"(ansi yellow)  🥀 no remote configured(ansi reset)"
        let provider = (["GitHub" "GitLab" "manual URL"] | input list --fuzzy "Add remote:")
        let remote_url = if $provider == "GitHub" {
            let token = (get-github-token)
            if $token == null { print -e "  🥀 no token"; return }
            github-create-repo ($repo | path basename) $token
        } else if $provider == "GitLab" {
            let token = (get-gitlab-token)
            if $token == null { print -e "  🥀 no token"; return }
            gitlab-create-repo ($repo | path basename) $token
        } else {
            input "  Remote URL: " | str trim
        }
        if ($remote_url | is-empty) or $remote_url == null { print -e "  🥀 no URL provided"; return }
        let ra = (do { git -C $repo remote add origin $remote_url } | complete)
        if $ra.exit_code != 0 { render-failure "REMOTE" $ra.stderr; return }
        print $"(ansi green)  🌹 remote → ($remote_url)(ansi reset)"
    }

    # Remote reachability before anything else
    if (check-remote-reachable $repo) { return }

    let t_start = (date now)

    # ── Entry prompt: enter=fast, space=interactive ──────────────────────────
    let mode = (manifold-entry-prompt $repo $bm)

    if $mode == "abort" { return }

    if $mode == "fast" {
        run-commit-push $repo $bm $msg
        return
    }

    # ── Interactive hub ──────────────────────────────────────────────────────
    if $mode == "interactive" {
        loop {
            let action = (interactive-hub $repo)

            if $action == "abort" { return }

            if $action == "branches" {
                interactive-branches $repo
                continue
            }

            if $action == "commit" {
                run-commit-push $repo (resolve-branch $repo) $msg
                return
            }
        }
    }
}

# =============================================================================
# SECTION 10 — CONVENIENCE COMMANDS
# =============================================================================
def git-undo [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo found"; return }
    let branch = (resolve-branch $repo)
    if ($branch | str starts-with "__") { print -e $"🥀 cannot undo in state: ($branch)"; return }
    let has_parent = (try { (do { git -C $repo rev-parse HEAD~1 } | complete).exit_code == 0 } catch { false })
    if not $has_parent { print -e "🥀 no parent commit — nothing to undo"; return }
    let r = (do { git -C $repo reset --soft HEAD~1 } | complete)
    if $r.exit_code != 0 { print -e $"  🥀 undo failed: ($r.stderr)" }
    else { print $"  🌹 last commit undone — changes kept staged" }
}

def git-restore-op [ref: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo found"; return }
    let branch = (resolve-branch $repo)
    if ($branch | str starts-with "__") { print -e $"🥀 cannot restore in state: ($branch)"; return }
    let r = (do { git -C $repo reset --hard $ref } | complete)
    if $r.exit_code != 0 { print -e $"  🥀 restore failed: ($r.stderr)" }
    else { print $"  🌹 restored to ($ref)" }
}

def git-amend [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo found"; return }
    let branch = (resolve-branch $repo)
    if ($branch | str starts-with "__") { print -e $"🥀 cannot amend in state: ($branch)"; return }
    let author = $"($config.author_name) <($config.author_email)>"
    git -C $repo add -A | ignore
    let r = (do { git -C $repo commit --amend --no-edit --author $author } | complete)
    if $r.exit_code != 0 { print -e $"  🥀 amend failed: ($r.stderr)"; return }
    print $"  🌹 amended HEAD"
    git -C $repo log --oneline -3 | print
}

def git-branch [name: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo found"; return }
    let r = (do { git -C $repo checkout -b $name } | complete)
    if $r.exit_code != 0 { print -e $"  🥀 branch create failed: ($r.stderr)"; return }
    print $"  🌹 switched to new branch ($name)"
}

def git-merge [branch: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo found"; return }
    let current = (resolve-branch $repo)
    if ($current | str starts-with "__") { print -e $"🥀 cannot merge in state: ($current)"; return }
    if ($current | is-empty) { print -e "🥀 not on a branch"; return }
    let rb = (do { git -C $repo rebase $current $branch } | complete)
    if $rb.exit_code != 0 {
        git -C $repo rebase --abort | ignore
        print -e $"  🥀 rebase of ($branch) onto ($current) failed: ($rb.stderr)"
        return
    }
    let co = (do { git -C $repo checkout $current } | complete)
    if $co.exit_code != 0 { print -e $"  🥀 checkout failed: ($co.stderr)"; return }
    let ff = (do { git -C $repo merge --ff-only $branch } | complete)
    if $ff.exit_code != 0 {
        print -e $"  🥀 fast-forward failed — ($branch) is not a strict ancestor after rebase: ($ff.stderr)"
        return
    }
    print $"  🌹 ($branch) merged into ($current)"
    let pr = (do-push $repo $current)
    if $pr.exit_code != 0 { print -e $"  🥀 push failed: ($pr.stderr)"; return }
    print $"  🌹 pushed ($current)"
}

def git-log [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo found"; return }
    print ""
    print $"(ansi red_bold)  🌹 LOG(ansi reset)"
    print ""
    git -C $repo log --oneline --graph --decorate -20
    print ""
}

def git-tag [name: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo found"; return }
    let r = (do { git -C $repo tag $name } | complete)
    if $r.exit_code != 0 { print -e $"  🥀 tag failed: ($r.stderr)"; return }
    let pr = (do { git -C $repo push origin $name } | complete)
    if $pr.exit_code != 0 { print -e $"  🥀 push tag failed: ($pr.stderr)"; return }
    print $"  🌹 tag ($name) pushed"
}

def git-branch-here [name: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo found"; return }
    let r = (do { git -C $repo branch $name } | complete)
    if $r.exit_code != 0 { print -e $"  🥀 branch create failed: ($r.stderr)"; return }
    do-push $repo $name | ignore
    print $"  🌹 branch ($name) created at HEAD and pushed"
}

def git-fix-authors [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo found"; return }
    let branch = (resolve-branch $repo)
    if ($branch | str starts-with "__") { print -e $"🥀 cannot fix authors in state: ($branch)"; return }
    if ($branch | is-empty) { print -e "🥀 not on a branch"; return }
    if not (remote-branch-exists $repo $branch) { print -e "🥀 no remote branch to compare"; return }
    let author = $"($config.author_name) <($config.author_email)>"
    let exec_cmd = $"git commit --amend --author='($author)' --no-edit"
    let r = (do { git -C $repo rebase $"origin/($branch)" --exec $exec_cmd } | complete)
    if $r.exit_code != 0 {
        git -C $repo rebase --abort | ignore
        print -e $"  🥀 author fix failed: ($r.stderr)"
        return
    }
    print $"  🌹 authors fixed"
}

def git-split [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo found"; return }
    let branch = (resolve-branch $repo)
    if ($branch | str starts-with "__") { print -e $"🥀 cannot split in state: ($branch)"; return }
    let has_parent = (try { (do { git -C $repo rev-parse HEAD~1 } | complete).exit_code == 0 } catch { false })
    if not $has_parent { print -e "🥀 no parent commit — nothing to split"; return }
    let r = (do { git -C $repo reset HEAD~1 } | complete)
    if $r.exit_code != 0 { print -e $"  🥀 split failed: ($r.stderr)"; return }
    print "  🌹 last commit unstaged — use Magit or git add -p to re-commit in pieces"
}

def git-squash [n: int = 2] {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo found"; return }
    let branch = (resolve-branch $repo)
    if ($branch | str starts-with "__") { print -e $"🥀 cannot squash in state: ($branch)"; return }
    let total_commits = (try { git -C $repo rev-list --count HEAD | str trim | into int } catch { 0 })
    if $n >= $total_commits { print -e $"  🥀 cannot squash ($n) commits — repo only has ($total_commits)"; return }
    let has_ancestor = (try { (do { git -C $repo rev-parse $"HEAD~($n)" } | complete).exit_code == 0 } catch { false })
    if not $has_ancestor { print -e $"  🥀 HEAD~($n) does not exist"; return }
    let r = (do { git -C $repo reset --soft $"HEAD~($n)" } | complete)
    if $r.exit_code != 0 { print -e $"  🥀 squash failed: ($r.stderr)"; return }
    let ts     = (date now | format date "%Y-%m-%d %H:%M")
    let author = $"($config.author_name) <($config.author_email)>"
    let ci = (do { git -C $repo commit -m $"[($branch)] squash ($ts)" --author $author } | complete)
    if $ci.exit_code != 0 { print -e $"  🥀 commit failed: ($ci.stderr)"; return }
    print $"  🌹 squashed ($n) commits"
}

def git-reflog [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo found"; return }
    print ""
    print $"(ansi red_bold)  🌹 REFLOG(ansi reset)"
    print ""
    git -C $repo reflog --oneline -20
    print ""
}

def git-stats-json [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "🥀 no repo found"; return }
    let branch = (resolve-branch $repo | default "")
    let is_real_branch = (not ($branch | str starts-with "__")) and ($branch | is-not-empty)
    let sync   = if $is_real_branch { resolve-ahead-behind $repo $branch } else { { ahead: 0 behind: 0 } }
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
    {
        name: git_undo
        modifier: control
        keycode: char_z
        mode: [emacs, vi_insert]
        event: { send: executehostcommand cmd: "git-undo" }
    }
    {
        name: git_amend
        modifier: control
        keycode: char_a
        mode: [emacs, vi_insert]
        event: { send: executehostcommand cmd: "git-amend" }
    }
])