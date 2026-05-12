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
    github_user:      "CogitoGITHUB"
    github_token_path: null
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

def get-github-token [] {
    let secrets_dir = ($env.HOME | path join ".secrets")
    let token_path  = ($secrets_dir | path join "github_token")
    let gitignore   = ($secrets_dir | path join ".gitignore")
    let jjignore    = ($secrets_dir | path join ".jjignore")
    if not ($secrets_dir | path exists) { mkdir $secrets_dir }
    if not ($gitignore | path exists) { "*" | save -f $gitignore }
    if not ($jjignore  | path exists) { "*" | save -f $jjignore  }
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
    let jjignore    = ($secrets_dir | path join ".jjignore")
    if not ($secrets_dir | path exists) { mkdir $secrets_dir }
    if not ($gitignore | path exists) { "*" | save -f $gitignore }
    if not ($jjignore  | path exists) { "*" | save -f $jjignore  }
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

def bootstrap-repo [] {
    let repo = (pwd)
    let repo_name = ($repo | path basename)
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
    print $"(ansi grey)  No git/jj repo found — bootstrapping ($repo_name).(ansi reset)"
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
    let ji = (do { jj git init --colocate $repo } | complete)
    if $ji.exit_code != 0 { print -e $"(ansi red_bold)  ✗ jj init failed:(ansi reset) ($ji.stderr)"; return false }
    print $"(ansi green)  ✓ jj colocated(ansi reset)"
    jj config set --user user.name  $config.author_name
    jj config set --user user.email $config.author_email
    let bm = $config.default_branch
    let bmc = (do { jj --repository $repo bookmark create $bm } | complete)
    if $bmc.exit_code != 0 { print $"(ansi yellow)  ⚠ bookmark create: ($bmc.stderr)(ansi reset)" } else { print $"(ansi green)  ✓ bookmark ($bm) created(ansi reset)" }
    let ts = (date now | format date "%Y-%m-%d %H:%M")
    let author_flag = $"($config.author_name) <($config.author_email)>"
    let dc = (do { jj --repository $repo metaedit -m $"[($bm)] init ($ts)" --author $author_flag } | complete)
    if $dc.exit_code != 0 { print $"(ansi yellow)  ⚠ metaedit: ($dc.stderr)(ansi reset)" }
    jj --repository $repo bookmark set $bm -r '@' | ignore
    if ($remote_url | str starts-with "git@") or ($remote_url | str starts-with "ssh://") {
        let ssh_ok = (ensure-ssh-key)
        if not $ssh_ok { return false }
    }
    jj --repository $repo bookmark track $bm --remote=origin | ignore
    let pr = (do { jj --repository $repo git push --bookmark $bm } | complete)
    if $pr.exit_code != 0 {
        let pr2 = (do { jj --repository $repo git push --bookmark $bm } | complete)
        if $pr2.exit_code != 0 { print -e $"(ansi red_bold)  ✗ push failed:(ansi reset) ($pr2.stderr)"; return false }
    }
    print $"(ansi green)  ✓ pushed → ($remote_url) on ($bm)(ansi reset)"
    true
}

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
# Delimiter \u{001E} (ASCII Record Separator) is used throughout to split
# jj template output. It cannot appear in commit messages, author names, or
# timestamps, so field parsing is safe regardless of message content.
# =============================================================================

# Safe delimiter — ASCII Record Separator, never in user-visible text
const SEP = "\u{001E}"

def list-bookmarks [repo: string] {
    try {
        jj --repository $repo bookmark list
        | lines | where { |l| $l | is-not-empty }
        | each { |l| $l | split row ":" | get 0 | str trim }
    } catch { [] }
}

def resolve-bookmark [repo: string] {
    let known = (list-bookmarks $repo)
    if ($known | is-empty) { return null }
    let on_parent = (try {
        jj --repository $repo log --no-graph -r '@-' --template $"bookmarks.join\(\"($SEP)\"\)"
        | str trim | split row $SEP | where { |l| $l | is-not-empty } | get 0
    } catch { "" })
    if ($on_parent | is-not-empty) and ($known | any { |b| $b == $on_parent }) { return $on_parent }
    let on_wc = (try {
        jj --repository $repo log --no-graph -r '@' --template $"bookmarks.join\(\"($SEP)\"\)"
        | str trim | split row $SEP | where { |l| $l | is-not-empty } | get 0
    } catch { "" })
    if ($on_wc | is-not-empty) and ($known | any { |b| $b == $on_wc }) { return $on_wc }
    $known | get 0
}

def resolve-ahead-behind [repo: string, bookmark: string] {
    let ahead = (try {
        let rev = $"remote_bookmarks\(exact:\"($bookmark)\"\)..($bookmark)"
        jj --repository $repo log --no-graph -r $rev --limit 100
        | lines | where { |l| $l | is-not-empty } | length | into string
    } catch { "?" })
    let behind = (try {
        let rev = $"($bookmark)..remote_bookmarks\(exact:\"($bookmark)\"\)"
        jj --repository $repo log --no-graph -r $rev --limit 100
        | lines | where { |l| $l | is-not-empty } | length | into string
    } catch { "?" })
    { ahead: $ahead  behind: $behind }
}

# Returns a list of records: { change commit age subject author }
# Uses SEP as field delimiter — safe against | in commit messages.
def fetch-commits-from [repo: string, n: int] {
    let tmpl = $"change_id.short\(8\)++\"($SEP)\"++commit_id.short\(8\)++\"($SEP)\"++author.timestamp\(\).ago\(\)++\"($SEP)\"++description.first_line\(\)++\"($SEP)\"++author.name\(\)++\"\\n\""
    try {
        jj --repository $repo log --no-graph --limit $n --template $tmpl
        | lines | where { |l| $l | is-not-empty }
        | each { |line|
            let p = ($line | split row $SEP)
            { change: ($p | get 0)  commit: ($p | get 1)  age: ($p | get 2)  subject: ($p | get 3)  author: ($p | get 4) }
        }
        | where { |row| ($row.subject | is-not-empty) }
    } catch {
        git -C $repo log --format="%h%x1e%ad%x1e%s%x1e%an" --date=relative $"-($n)"
        | lines | where { |l| $l | is-not-empty }
        | each { |line|
            let p = ($line | split row $SEP)
            { change: "—"  commit: ($p | get 0)  age: ($p | get 1)  subject: ($p | get 2)  author: ($p | get 3) }
        }
    }
}

def fetch-status-from [repo: string] {
    try {
        jj --repository $repo diff --summary
        | lines | where { |l| $l | is-not-empty }
    } catch { [] }
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
    let tmpl = $"id.short\(12\)++\"($SEP)\"++description++\"($SEP)\"++user++\"($SEP)\"++time.start\(\).ago\(\)++\"\\n\""
    try {
        jj --repository $repo op log --no-graph --limit $n --template $tmpl
        | lines | where { |l| $l | is-not-empty }
        | each { |line|
            let p = ($line | split row $SEP)
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

# Returns true if the workflow should abort.
# Offers three resolution options: fast-forward rebase, pull+rebase, or abort.
def check-behind [repo: string, bookmark: string] {
    if ($bookmark | is-empty) { return false }
    let behind = (try {
        let rev = $"($bookmark)..remote_bookmarks\(exact:\"($bookmark)\"\)"
        jj --repository $repo log --no-graph -r $rev --limit 100
        | lines | where { |l| $l | is-not-empty } | length
    } catch { 0 })
    if $behind == 0 { return false }

    let tmpl = $"commit_id.short\(8\)++\"($SEP)\"++author.timestamp\(\).ago\(\)++\"($SEP)\"++description.first_line\(\)++\"\\n\""
    let remote_commits = (try {
        let rev = $"($bookmark)..remote_bookmarks\(exact:\"($bookmark)\"\)"
        jj --repository $repo log --no-graph -r $rev --template $tmpl
        | lines | where { |l| $l | is-not-empty }
        | each { |line|
            let p = ($line | split row $SEP)
            { commit: ($p | get 0)  age: ($p | get 1)  subject: ($p | get 2) }
        }
    } catch { [] })

    render-error "BEHIND REMOTE" $"Bookmark ($bookmark) is ($behind) commit\(s\) behind remote." $remote_commits

    let choice = (
        [
            "fast-forward  — rebase local commits on top of remote (recommended)"
            "pull only     — fetch and move bookmark to remote tip, discard local"
            "abort         — exit and handle manually"
        ] | input list --fuzzy "Behind remote — how to proceed?"
    )

    if ($choice | str starts-with "abort") { return true }

    let author_flag = $"($config.author_name) <($config.author_email)>"

    if ($choice | str starts-with "fast-forward") {
        let local_rev = $"remote_bookmarks\(exact:\"($bookmark)\"\)..($bookmark)"
        let local_only_count = (try {
            jj --repository $repo log --no-graph -r $local_rev --limit 100
            | lines | where { |l| $l | is-not-empty } | length
        } catch { 0 })

        if $local_only_count == 0 {
            let remote_rev = $"remote_bookmarks\(exact:\"($bookmark)\"\)"
            let r = (do {
                jj --repository $repo bookmark set $bookmark -r $remote_rev
            } | complete)
            if $r.exit_code != 0 {
                print -e $"(ansi red_bold)  ✗ bookmark fast-forward failed:(ansi reset) ($r.stderr)"
                return true
            }
            print $"(ansi green)  ✓ bookmark fast-forwarded to remote tip(ansi reset)"
        } else {
            let remote_rev = $"remote_bookmarks\(exact:\"($bookmark)\"\)"
            let r = (do {
                jj --repository $repo rebase -s $"($bookmark)~($local_only_count)" -d $remote_rev
            } | complete)
            if $r.exit_code != 0 {
                let r2 = (do {
                    jj --repository $repo rebase -b $bookmark -d $remote_rev
                } | complete)
                if $r2.exit_code != 0 {
                    print -e $"(ansi red_bold)  ✗ rebase failed:(ansi reset) ($r2.stderr)"
                    return true
                }
            }
            jj --repository $repo bookmark set $bookmark -r '@-' | ignore
            print $"(ansi green)  ✓ local commits rebased onto remote tip(ansi reset)"
        }
        return false
    }

    if ($choice | str starts-with "pull only") {
        let local_rev = $"remote_bookmarks\(exact:\"($bookmark)\"\)..($bookmark)"
        let tmpl2 = $"change_id.short\(8\)++\"\\n\""
        let local_only = (try {
            jj --repository $repo log --no-graph -r $local_rev --template $tmpl2
            | lines | where { |l| $l | is-not-empty }
        } catch { [] })

        if not ($local_only | is-empty) {
            print $"(ansi yellow)  ⚠ abandoning ($local_only | length) local-only commit\(s\):(ansi reset)"
            $local_only | each { |id| print $"    ($id)" } | ignore
            let confirm = (["yes — discard them" "no — abort"] | input list --fuzzy "Discard local commits?")
            if not ($confirm | str starts-with "yes") { return true }
            for id in $local_only {
                jj --repository $repo abandon $id | ignore
            }
        }

        let remote_rev = $"remote_bookmarks\(exact:\"($bookmark)\"\)"
        let r = (do {
            jj --repository $repo bookmark set $bookmark -r $remote_rev
        } | complete)
        if $r.exit_code != 0 {
            print -e $"(ansi red_bold)  ✗ pull failed:(ansi reset) ($r.stderr)"
            return true
        }
        print $"(ansi green)  ✓ pulled — bookmark now at remote tip(ansi reset)"
        return false
    }

    true  # fallback abort
}

def check-conflicts [repo: string] {
    let tmpl = $"change_id.short\(8\)++\"($SEP)\"++description.first_line\(\)++\"\\n\""
    let conflicted = (try {
        jj --repository $repo log --no-graph -r 'conflicts()' --template $tmpl
        | lines | where { |l| $l | is-not-empty }
        | each { |l|
            let p = ($l | split row $SEP)
            { change: ($p | get 0) subject: ($p | get 1) }
        }
    } catch { [] })
    if not ($conflicted | is-empty) {
        render-error "UNRESOLVED CONFLICTS" "Resolve before committing." $conflicted
        let choice = (["launch jj resolve" "abort"] | input list --fuzzy "Conflicts detected:")
        if $choice == "launch jj resolve" {
            jj --repository $repo resolve
            let still = (try { jj --repository $repo log --no-graph -r 'conflicts()' | str trim | is-not-empty } catch { false })
            if $still { print -e $"(ansi red_bold)  ✗ conflicts remain(ansi reset)"; return true }
            print $"(ansi green)  ✓ conflicts resolved(ansi reset)"
            return false
        }
        return true
    }
    false
}

def check-large-files [repo: string] {
    let limit_bytes = ($config.max_file_size_mb * 1024 * 1024)
    let large = (try {
        jj --repository $repo diff --summary
        | lines | where { |l| $l | is-not-empty }
        | each { |line|
            let parts = ($line | str trim | split row " " | where { |p| $p | is-not-empty })
            let file  = ($parts | get 1)
            let full  = ($repo | path join $file)
            let sz    = (try { (ls $full | get 0.size) } catch { 0 })
            if ($sz | into int) > $limit_bytes { $file } else { null }
        }
        | where { |x| $x != null }
    } catch { [] })
    if not ($large | is-empty) {
        render-error "LARGE FILES DETECTED" $"Files exceed ($config.max_file_size_mb)MB — consider .gitignore or git-lfs." $large
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Large files — proceed?")
        $choice == "abort"
    } else { false }
}

def check-stash [repo: string] {
    let count = (try { git -C $repo stash list | lines | length } catch { 0 })
    if $count > 0 {
        let stashes = (git -C $repo stash list | lines)
        render-error "STASHED CHANGES" $"($count) stash\(es\) detected." $stashes
        let choice = (["continue anyway" "abort"] | input list --fuzzy "Stash detected — proceed?")
        $choice == "abort"
    } else { false }
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
        render-error "REMOTE UNREACHABLE" $"Cannot reach ($host) via SSH." [
            { hint: "Check network / VPN" }
            { hint: $"ssh -T git@($host)" }
        ]
        true
    } else { false }
}

def check-divergence [repo: string, bookmark: string] {
    if ($bookmark | is-empty) { return false }
    let diverged = (try {
        let rev_a = $"remote_bookmarks\(exact:\"($bookmark)\"\)..($bookmark)"
        let rev_b = $"($bookmark)..remote_bookmarks\(exact:\"($bookmark)\"\)"
        let a = (jj --repository $repo log --no-graph -r $rev_a --limit 5 | lines | where { |l| $l | is-not-empty } | length)
        let b = (jj --repository $repo log --no-graph -r $rev_b --limit 5 | lines | where { |l| $l | is-not-empty } | length)
        $a > 0 and $b > 0
    } catch { false })
    if $diverged {
        render-error "DIVERGED HISTORY" $"($bookmark) has diverged from remote. Local and remote have different commits." [
            { option: "rebase local onto remote  →  safe, rewrites local" }
            { option: "squash into remote head   →  loses local structure" }
            { option: "abort                     →  fix manually" }
        ]
        let choice = (["rebase onto remote" "squash into remote" "abort"] | input list --fuzzy "Divergence strategy:")
        if $choice == "abort" { return true }
        let author_flag = $"($config.author_name) <($config.author_email)>"
        if $choice == "rebase onto remote" {
            let remote_rev = $"remote_bookmarks\(exact:\"($bookmark)\"\)"
            let r = (do { jj --repository $repo rebase -d $remote_rev } | complete)
            if $r.exit_code != 0 { print -e $"(ansi red_bold)  ✗ rebase failed:(ansi reset) ($r.stderr)"; return true }
            jj --repository $repo bookmark set $bookmark -r '@-' | ignore
            print $"(ansi green)  ✓ rebased onto remote ($bookmark)(ansi reset)"
        } else {
            let remote_rev = $"remote_bookmarks\(exact:\"($bookmark)\"\)"
            let r = (do { jj --repository $repo squash --into $remote_rev } | complete)
            if $r.exit_code != 0 { print -e $"(ansi red_bold)  ✗ squash failed:(ansi reset) ($r.stderr)"; return true }
            jj --repository $repo bookmark set $bookmark -r $remote_rev | ignore
            print $"(ansi green)  ✓ squashed into remote head(ansi reset)"
        }
        false
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
# SECTION 6 — PUSH HELPER
# =============================================================================
def do-push [repo: string, bm: string] {
    let author_flag = $"($config.author_name) <($config.author_email)>"
    try {
        let tmpl = $"change_id.short\(8\)++\"\\n\""
        let rev = $"remote_bookmarks\(exact:\"($bm)\"\)..($bm)"
        jj --repository $repo log --no-graph -r $rev --template $tmpl
        | lines | where { |l| $l | is-not-empty }
        | each { |id|
            let r = (do { jj --repository $repo metaedit -r $id --author $author_flag } | complete)
            if $r.exit_code != 0 and not ($r.stderr | str contains "Nothing changed") {
                print $"(ansi yellow)  ⚠ author stamp ($id): ($r.stderr)(ansi reset)"
            }
        }
    } catch { }
    jj --repository $repo bookmark track $bm --remote=origin | ignore
    let r = (do { jj --repository $repo git push --bookmark $bm } | complete)
    if $r.exit_code != 0 and ($r.stderr | str contains "Non-tracking remote bookmark") {
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
    let repo = (find-repo-root)
    if $repo == null {
        print -n "\e[2J\e[H"
        print ""
        print $"(ansi red_bold)🌹 MANIFOLD // RESHAPING HISTORY 🌹(ansi reset)"
        print $"(ansi grey)  No git/jj repo found in ($env.PWD) or any parent.(ansi reset)"
        print ""
        let choice = (["bootstrap repo here" "abort"] | input list --fuzzy "No repo found — bootstrap from dir name?")
        if $choice == "abort" { return }
        let ok = (bootstrap-repo)
        if not $ok { return }
        ManifoldOS-Reshaping-History $msg
        return
    }

    let init_ok = (ensure-jj-initialized $repo)
    if not $init_ok { return }

    let has_remote = (try { git -C $repo remote | str trim | is-not-empty } catch { false })
    if not $has_remote {
        print $"(ansi yellow)  ⚠ no remote configured(ansi reset)"
        let provider = (["GitHub" "GitLab" "manual URL"] | input list --fuzzy "Add remote:")
        let remote_url = if $provider == "GitHub" {
            let token = (get-github-token)
            if $token == null { print -e "  ✗ no token"; return }
            github-create-repo ($repo | path basename) $token
        } else if $provider == "GitLab" {
            let token = (get-gitlab-token)
            if $token == null { print -e "  ✗ no token"; return }
            gitlab-create-repo ($repo | path basename) $token
        } else {
            input "  Remote URL: " | str trim
        }
        if ($remote_url | is-empty) or $remote_url == null { print -e "  ✗ no URL provided"; return }
        let ra = (do { git -C $repo remote add origin $remote_url } | complete)
        if $ra.exit_code != 0 { print -e $"(ansi red_bold)  ✗ remote add failed:(ansi reset) ($ra.stderr)"; return }
        print $"(ansi green)  ✓ remote → ($remote_url)(ansi reset)"
    }

    let bookmark = (resolve-bookmark $repo)
    let bm = if ($bookmark | is-empty) or $bookmark == null {
        let git_branch = (try { git -C $repo branch --show-current | str trim } catch { "" })
        let name = if ($git_branch | is-not-empty) { $git_branch } else { $config.default_branch }
        print $"(ansi yellow)  ⚠ no bookmark — creating ($name)(ansi reset)"
        let bmc = (do { jj --repository $repo bookmark create $name --at '@-' } | complete)
        if $bmc.exit_code != 0 {
            let bmc2 = (do { jj --repository $repo bookmark create $name } | complete)
            if $bmc2.exit_code != 0 {
                print $"(ansi yellow)  ⚠ bookmark create failed \(non-fatal\): ($bmc2.stderr)(ansi reset)"
                ""
            } else { print $"(ansi green)  ✓ bookmark ($name) created(ansi reset)"; $name }
        } else { print $"(ansi green)  ✓ bookmark ($name) created(ansi reset)"; $name }
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
    if (check-divergence $repo $bm)       { return }
    if (check-behind $repo $bm)           { return }
    if (check-conflicts $repo)            { return }
    if (check-remote-reachable $repo)     { return }
    if (check-stash $repo)                { return }
    if (check-large-files $repo)          { return }
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
    jj --repository $repo debug snapshot | ignore
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
    let push_result  = (do-push $repo $bm)
    let elapsed_push = $"(((date now) - $t) / 1sec * 1000 | math round)ms"
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

# Undo last jj operation
def jj-undo [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let result = (do { jj --repository $repo op undo } | complete)
    if $result.exit_code != 0 { print -e $"(ansi red_bold)  ✗ undo failed:(ansi reset) ($result.stderr)" }
    else { print $"(ansi green)  ✓ undone(ansi reset)"; fetch-op-log-from $repo 3 | print }
}

# Restore to a specific op id
def jj-restore-op [op_id: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let result = (do { jj --repository $repo op restore $op_id } | complete)
    if $result.exit_code != 0 { print -e $"(ansi red_bold)  ✗ restore failed:(ansi reset) ($result.stderr)" }
    else { print $"(ansi green)  ✓ restored to ($op_id)(ansi reset)" }
}

# Amend last real commit with current working copy changes (no message change)
def jj-amend [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let author_flag = $"($config.author_name) <($config.author_email)>"
    jj --repository $repo debug snapshot | ignore
    let r = (do { jj --repository $repo squash } | complete)
    if $r.exit_code != 0 { print -e $"(ansi red_bold)  ✗ squash failed:(ansi reset) ($r.stderr)"; return }
    let tmpl = $"change_id.short\(8\)++\"\\n\""
    let id = (try { jj --repository $repo log --no-graph -r '@-' --template $tmpl | str trim } catch { "" })
    if ($id | is-not-empty) {
        jj --repository $repo metaedit -r $id --author $author_flag | ignore
    }
    print $"(ansi green)  ✓ amended @-(ansi reset)"
    let log_tmpl = $"change_id.short\(8\)++\" \"++description.first_line\(\)++\"\\n\""
    jj --repository $repo log --no-graph --limit 3 --template $log_tmpl | print
}

# Create a new feature branch workspace, switch to it
def jj-branch [name: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let author_flag = $"($config.author_name) <($config.author_email)>"
    let bmc = (do { jj --repository $repo bookmark create $name -r '@-' } | complete)
    if $bmc.exit_code != 0 { print -e $"(ansi red_bold)  ✗ bookmark create failed:(ansi reset) ($bmc.stderr)"; return }
    print $"(ansi green)  ✓ bookmark ($name) created at @-(ansi reset)"
    let nr = (do { jj --repository $repo new $name --no-edit } | complete)
    if $nr.exit_code != 0 { print $"(ansi yellow)  ⚠ jj new: ($nr.stderr)(ansi reset)" }
    print $"(ansi green)  ✓ working on ($name) — commit and run ManifoldOS-Reshaping-History to push(ansi reset)"
}

# Merge a named branch back into the current bookmark and push
def jj-merge [branch: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let bm = (resolve-bookmark $repo | default $config.default_branch)
    let author_flag = $"($config.author_name) <($config.author_email)>"
    let r = (do { jj --repository $repo rebase -b $branch -d $bm } | complete)
    if $r.exit_code != 0 { print -e $"(ansi red_bold)  ✗ rebase failed:(ansi reset) ($r.stderr)"; return }
    jj --repository $repo bookmark set $bm -r $branch | ignore
    let tmpl = $"change_id.short\(8\)++\"\\n\""
    let id = (try { jj --repository $repo log --no-graph -r $bm --template $tmpl | str trim } catch { "" })
    if ($id | is-not-empty) { jj --repository $repo metaedit -r $id --author $author_flag | ignore }
    print $"(ansi green)  ✓ ($branch) merged into ($bm)(ansi reset)"
    let pr = (do-push $repo $bm)
    if $pr.exit_code != 0 { print -e $"(ansi red_bold)  ✗ push failed:(ansi reset) ($pr.stderr)"; return }
    print $"(ansi green)  ✓ pushed ($bm)(ansi reset)"
}

# Pretty graph log of mutable commits only
def jj-log [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // LOG 🌹(ansi reset)"
    print $"(ansi grey)  mutable commits — local history(ansi reset)"
    print ""
    jj --repository $repo log -r 'mutable()'
    print ""
}

# Tag the current bookmark tip and push tags
def jj-tag [name: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let bm = (resolve-bookmark $repo | default $config.default_branch)
    let tmpl = $"commit_id.short\(8\)++\"\\n\""
    let commit = (try { jj --repository $repo log --no-graph -r $bm --template $tmpl | str trim } catch { "" })
    if ($commit | is-empty) { print -e "  ✗ could not resolve bookmark tip"; return }
    let r = (do { git -C $repo tag $name $commit } | complete)
    if $r.exit_code != 0 { print -e $"(ansi red_bold)  ✗ tag failed:(ansi reset) ($r.stderr)"; return }
    let pr = (do { git -C $repo push origin $name } | complete)
    if $pr.exit_code != 0 { print -e $"(ansi red_bold)  ✗ push tag failed:(ansi reset) ($pr.stderr)"; return }
    print $"(ansi green)  ✓ tag ($name) → ($commit) pushed(ansi reset)"
}

# Set bookmark at @- and push
def jj-bookmark-here [name: string] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    jj --repository $repo bookmark set $name -r '@-'
    do-push $repo $name
    print $"(ansi green)  ✓ bookmark ($name) set on @- and pushed(ansi reset)"
}

# Fix all mutable commit authors
def jj-fix-authors [] {
    let repo = (find-repo-root)
    if $repo == null { print -e "✗ no repo found"; return }
    let author_flag = $"($config.author_name) <($config.author_email)>"
    let tmpl = $"change_id.short\(8\)++\"\\n\""
    jj --repository $repo log --no-graph -r 'mutable()' --template $tmpl
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
    {
        name: jj_log
        modifier: control
        keycode: char_l
        mode: emacs
        event: { send: executehostcommand cmd: "jj-log" }
    }
    {
        name: jj_amend
        modifier: control
        keycode: char_a
        mode: emacs
        event: { send: executehostcommand cmd: "jj-amend" }
    }
])