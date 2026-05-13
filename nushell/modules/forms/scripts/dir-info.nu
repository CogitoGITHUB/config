# =============================================================================
# COMMANDS CONFIG — add/remove actions here
# =============================================================================
const COMMANDS = [
    { key: "w",  command: "Weather" }
    { key: "n",  command: "Capture" }
    { key: "g",  command: "Push" }
    { key: "r",  command: "Redraw" }
    { key: "l",  command: "Clear" }
    { key: " ",  command: "Exit" }
]

# =============================================================================
# WORKSPACE CONFIG — add/remove files here only, nothing else needs touching
# =============================================================================
const WORKSPACE = [
    { key: "a"  file: "Agents.org"        label: "AGENTS"          subtitle: "actors, roles, contacts relevant to this workspace" }
    { key: "o"  file: "Blueprint.org"     label: "BLUEPRINT"       subtitle: "structural plans and design decisions" }
    { key: "e"  file: "Rules.org"         label: "RULES"           subtitle: "imposed constraints. Self-defined boundaries that structure action and reduce variance. Optional, but costly to ignore." }
    { key: "i"  file: "Journal.org"       label: "JOURNAL"         subtitle: "stripped observations. Events, reactions, deviations. No storytelling, only what can be examined later." }
    { key: "d"  file: "Context.org"       label: "CONTEXT"         subtitle: "operational surroundings. Timing, environment, dependencies, pressures. The conditions that shape outcomes." }
    { key: "h"  file: "State.org"         label: "STATE"           subtitle: "a current-state register. What exists, what's complete, what's degraded. A contrast between intent and reality." }
    { key: "6"  file: "Laws.org"          label: "LAWS"            subtitle: "codified legal reality. Statutes, regulations, and case law within the relevant jurisdiction. Enforceable, external, indifferent to intent." }
    { key: "p"  file: "Philosophy.org"    label: "PHILOSOPHY"      subtitle: "foundational logic. The reasoning that justifies action. If this fails, the rest becomes noise." }
    { key: "v"  file: "Advantages.org"    label: "ADVANTAGES"      subtitle: "leverage inventory. Structural edges, asymmetries, resources that increase probability of success." }
    { key: "q"  file: "Quotes.org"        label: "QUOTES"          subtitle: "compressed statements. Language retained for precision and recall. Only what remains accurate under scrutiny." }
    { key: "x"  file: "TrapsInternal.org" label: "TRAPS INTERNAL"  subtitle: "known failure modes. Patterns that have caused or will cause damage. Recognized in advance, not in retrospect." }
    { key: "y"  file: "TrapsExternal.org" label: "TRAPS EXTERNAL"  subtitle: "traps constructed for others. Positions, framings, and conditions that constrain opposing action." }
    { key: "1"  file: "Evidence.org"      label: "EVIDENCE"        subtitle: "observations and data points that have changed your thinking. What moved you and why." }
    { key: "2"  file: "Hypotheses.org"    label: "HYPOTHESES"      subtitle: "open questions actively worked toward. Not todos, not facts — live uncertainties." }
    { key: "3"  file: "Experiments.org"   label: "EXPERIMENTS"     subtitle: "things actively being tested. Hypothesis, method, current result." }
    { key: "4"  file: "Mastery.org"       label: "MASTERY"         subtitle: "honest self-assessment per skill. What is internalized vs what is surface familiarity." }
    { key: "5"  file: "Sources.org"       label: "SOURCES"         subtitle: "books, papers, people, repositories worth returning to. Vetted only, no speculative bookmarks." }
    { key: "t"  file: "TODO.org"          label: "TODO"            subtitle: "a ledger of unfinished business. No speculation. Only executable items that remain open and consume attention." }
]

# =============================================================================
# ORG PARSER
# =============================================================================
export def parse-org [org_path: string] {
    open --raw $org_path
    | lines
    | each {|line|
        try {
            let level = ($line | parse -r '^(\*+) ' | get capture0.0? | default "" | str length)
            if $level > 0 {
                let content = ($line | str replace -r '^\*+ ' "")
                let keyword = if ($content | str starts-with "TODO ") { "TODO" } else if ($content | str starts-with "DONE ") { "DONE" } else { "" }
                let clean = if ($keyword | is-not-empty) { $content | str replace -r '^(TODO|DONE) ' "" } else { $content }
                let is_overdue = ($line | str contains "DEADLINE:") or ($line | str contains "SCHEDULED:")
                if ($clean | str starts-with "http") {
                    {level: $level, kind: "link", keyword: $keyword, description: $clean, overdue: $is_overdue}
                } else {
                    {level: $level, kind: "task", keyword: $keyword, description: $clean, overdue: $is_overdue}
                }
            } else { null }
        } catch { null }
    }
    | compact
}

def print-section [path: string, label: string, subtitle: string] {
    if ($path | path exists) {
        let rows = (parse-org $path)
        let count = ($rows | length)
        let status = if $count > 0 { $"● ($count)" } else { "○ empty" }
        print ""
        print $"(ansi red_bold)  🌹 ($label)(ansi reset)"
        [{subtitle: $subtitle, status: $status}] | table | print
        if $count > 0 {
            $rows | select keyword description overdue | table | print
        }
    }
}

# =============================================================================
# REPO STATUS
# =============================================================================
def repo-status-line [] {
    try {
        let log_raw = (do { jj log --no-graph -r '@ | @-' --limit 2 } | complete | get stdout | str trim | lines | where { |l| $l | is-not-empty })
        let status_raw = (do { jj status } | complete | get stdout | str trim | lines | where { |l| $l | is-not-empty })
        let all = ($log_raw ++ $status_raw | each { |l| {info: $l} })
        if ($all | length) > 0 {
            print ""
            print $"(ansi red_bold)  🌹 REPO(ansi reset)"
            $all | table | print
        }
    } catch { }
}

# =============================================================================
# WORKSPACE DRAW — driven entirely by WORKSPACE table
# =============================================================================
def ensure-workspace-files [] {
    for entry in $WORKSPACE {
        let fpath = ($env.PWD | path join $entry.file)
        if not ($fpath | path exists) { touch $fpath }
    }
}

def draw-workspace [] {
    let dir_name = ($env.PWD | path basename)
    print ""
    print ($env.PWD | path split)
    print $"(ansi red_bold)  ($dir_name)(ansi reset)"
    ls | select name type size modified | sort-by name | table | print
    print ""
    print $"(ansi red_bold)  🌹 COMMANDS(ansi reset)"
    let file_rows = ($WORKSPACE | each { |e| { key: $e.key, command: $e.label } })
    let cmd_rows = ($COMMANDS | each { |e| { key: $e.key, command: $e.command } })
    $file_rows ++ $cmd_rows | table | print
    print ""
    print $"(ansi grey)  🌹 \"To choose is to affirm, by your choice, the weight of your own existence.(ansi reset)"
    print $"(ansi grey)     You are condemned to be free.\" — Jean-Paul Sartre 🌹(ansi reset)"
    print ""
    for entry in $WORKSPACE {
        print-section ($env.PWD | path join $entry.file) $entry.label $entry.subtitle
    }
    print ""
    repo-status-line
    print ""
}

# =============================================================================
# QUICK CAPTURE
# =============================================================================
def quick-capture [] {
    let todo_path = ($env.PWD | path join "TODO.org")
    print -n $"(ansi purple)  New TODO heading: (ansi reset)"
    let text = (input "" | str trim)
    if ($text | is-not-empty) {
        $"\n* TODO ($text)" | save --append $todo_path
        print $"(ansi green)  ✓ appended to TODO.org(ansi reset)"
    } else {
        print $"(ansi grey)  — nothing captured(ansi reset)"
    }
}

# =============================================================================
# PROMPT LINE
# =============================================================================
def prompt-line [] {
    print ""
}

# =============================================================================
# MAIN LOOP
# =============================================================================
def workspace-loop [] {
    mut running    = true
    mut needs_draw = true

    let file_map = ($WORKSPACE | each { |e| { key: $e.key, path: ($env.PWD | path join $e.file) } })

    loop {
        if not $running { break }
        if $needs_draw { draw-workspace }
        $needs_draw = true

        prompt-line
        let code = (try { input listen --types [key] } catch { {code: "escape"} }).code

        let matched = ($file_map | where key == $code | get 0?)
        if ($matched | is-not-empty) {
            emacs $matched.path
        } else {
            match $code {
                "n" => { quick-capture }
                "w" => { ManifoldOS-Weather; $needs_draw = false }
                "g" => {
                    ManifoldOS-Reshaping-History
                    $running = false
                }
                "r" => { }
                "l" => { clear; $needs_draw = false; $running = false }
                _ => {
                    clear
                    print ""
                    repo-status-line
                    print ""
                    print $"(ansi grey)  🌹 \"To choose is to affirm, by your choice, the weight of your own existence.(ansi reset)"
                    print $"(ansi grey)     You are condemned to be free.\" — Jean-Paul Sartre 🌹(ansi reset)"
                    print ""
                    print $"(ansi red_bold)  🌹 Reshaping is only adaptation under pressure 🌹(ansi reset)"
                    print ""
                    $env.__skip_workspace = true
                    $running = false
                }
            }
        }
    }
}

# =============================================================================
# EXPORTS
# =============================================================================
export def maybe-open-todo [] {
    if ($env | get -i __skip_workspace) == true {
        $env.__skip_workspace = false
        return
    }
    ensure-workspace-files
    workspace-loop
}

export def show-dir-info [] {
    draw-workspace
}