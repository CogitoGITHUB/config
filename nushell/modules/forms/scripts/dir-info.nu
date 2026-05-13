# =============================================================================
# FZF
# =============================================================================
def fzf-open [path?: string] {
    let root = ($path | default ".")
    let file = (^bash -c $"fd --type f . '($root)' | fzf --preview 'bat --color=always --style=numbers {}' --preview-window 'right:60%:wrap' --prompt '  File> ' --header 'ENTER to open in emacs'" | str trim)
    if not ($file | is-empty) { ^emacs $file }
}

def fzf-bat [path?: string] {
    let root = ($path | default ".")
    let file = (^bash -c $"fd --type f . '($root)' | fzf --preview 'bat --color=always --style=numbers {}' --preview-window 'right:60%:wrap' --prompt '  File> ' --header 'ENTER to view in bat'" | str trim)
    if not ($file | is-empty) { ^bat --style=full --color=always $file }
}

# =============================================================================
# COMMANDS CONFIG
# =============================================================================
const COMMANDS = [
    { key: "w",  command: "Weather" }
    { key: "n",  command: "Capture" }
    { key: "p",  command: "In Progress (last TODO)" }
    { key: "s",  command: "Done (last active)" }
    { key: "d",  command: "Delete (last DONE only)" }
    { key: "u",  command: "fzf → emacs" }
    { key: "h",  command: "fzf → bat" }
    { key: "i",  command: "Describe commit (jj)" }
    { key: "g",  command: "Push (with confirm)" }
    { key: "m",  command: "Commands" }
    { key: "r",  command: "Redraw" }
    { key: "l",  command: "Clear" }
    { key: " ",  command: "Exit" }
]

# =============================================================================
# WORKSPACE CONFIG
# =============================================================================
const WORKSPACE = [
    { key: ""  file: "Agents.org"        label: "AGENTS"
      subtitle: "Who is in play"
      description: "Actors, roles, and contacts relevant to this workspace. Map their interests, capabilities, and relationship to your position. Know who moves, who watches, and who can be moved." }
    { key: ""  file: "Blueprint.org"     label: "BLUEPRINT"
      subtitle: "How it is built"
      description: "Structural plans and design decisions. The load-bearing logic of what you are building. Not goals — architecture. If this changes, everything downstream changes with it." }
    { key: ""  file: "Rules.org"         label: "RULES"
      subtitle: "What constrains action"
      description: "Imposed constraints and self-defined boundaries that structure action and reduce variance. Some are external and non-negotiable. Some are chosen. Know which is which — confusion here is expensive." }
    { key: ""  file: "Journal.org"       label: "JOURNAL"
      subtitle: "What actually happened"
      description: "Stripped observations only. Events, reactions, deviations from expectation. No storytelling, no interpretation at write time. Raw input for later analysis. If you are editorializing, you are doing it wrong." }
    { key: ""  file: "Context.org"       label: "CONTEXT"
      subtitle: "The conditions shaping outcomes"
      description: "Operational surroundings: timing, environment, dependencies, pressures, and constraints you did not choose. The same move lands differently in different context. This file explains why." }
    { key: ""  file: "State.org"         label: "STATE"
      subtitle: "Where things actually stand"
      description: "A current-state register. What exists, what is complete, what is degraded, what is blocked. A contrast between intent and reality. If this file is optimistic, it is lying to you." }
    { key: ""  file: "Laws.org"          label: "LAWS"
      subtitle: "What is enforceable"
      description: "Codified legal reality. Statutes, regulations, and case law within the relevant jurisdiction. Enforceable, external, and indifferent to intent. Know where the hard walls are before you map the gray zones." }
    { key: ""  file: "Philosophy.org"    label: "PHILOSOPHY"
      subtitle: "Why any of this is justified"
      description: "Foundational logic. The reasoning that authorizes your actions and defines what you are willing to do. If this fails under scrutiny, the rest becomes noise. Revisit it when you feel drift." }
    { key: ""  file: "Advantages.org"    label: "ADVANTAGES"
      subtitle: "What you have that others do not"
      description: "Leverage inventory. Structural edges, asymmetries, unique resources, and positional advantages that increase your probability of success. Be honest about what is real versus what is flattering." }
    { key: ""  file: "Leverage.org"      label: "LEVERAGE"
      subtitle: "What moves people and systems"
      description: "Relational and time-sensitive pressure points. Favors owed, information asymmetries, dependencies, and timing windows that give you disproportionate influence. Unlike Advantages, leverage expires — track when and how." }
    { key: ""  file: "Counters.org"      label: "COUNTERS"
      subtitle: "How this could be beaten"
      description: "Adversarial defense. The moves others could make against your position, and your pre-built responses. Think like your opponent. Map the attacks before they arrive. Offense without this is fragile." }
    { key: ""  file: "Signals.org"       label: "SIGNALS"
      subtitle: "What the environment is telling you now"
      description: "Leading indicators you are actively watching. Early pattern recognition before conclusions are warranted. Not evidence (retrospective) and not hypotheses (open questions) — signals are live inputs that may become either." }
    { key: ""  file: "Timing.org"        label: "TIMING"
      subtitle: "When things open and close"
      description: "Windows, deadlines, decay rates, and expiration of conditions. Most system failures are timing failures, not logic failures. Track when opportunities close, when leverage expires, and when the environment shifts." }
    { key: ""  file: "Quotes.org"        label: "QUOTES"
      subtitle: "Compressed precision"
      description: "Statements retained for accuracy and recall. Language that resists paraphrase without loss. Only what remains true under scrutiny and still useful six months later." }
    { key: ""  file: "TrapsInternal.nu" label: "TRAPS INTERNAL"
      subtitle: "How you fail yourself"
      description: "Known personal failure modes. Cognitive patterns, emotional triggers, and behavioral loops that have caused or will cause damage. The goal is recognition in advance, not diagnosis in retrospect." }
    { key: ""  file: "TrapsExternal.org" label: "TRAPS EXTERNAL"
      subtitle: "How you constrain others"
      description: "Traps constructed for opposing actors. Positions, framings, and conditions that limit their options or force unfavorable moves. Built deliberately, not reactively." }
    { key: ""  file: "Evidence.org"      label: "EVIDENCE"
      subtitle: "What changed your mind"
      description: "Observations and data points that have materially updated your thinking. Log what moved you and why. This is not a fact repository — it is a record of epistemic shifts." }
    { key: ""  file: "Hypotheses.org"    label: "HYPOTHESES"
      subtitle: "What you are still working out"
      description: "Open questions being actively pursued. Not todos, not facts — live uncertainties with enough structure to be tested. If a hypothesis has no path to resolution, it is speculation." }
    { key: ""  file: "Experiments.org"   label: "EXPERIMENTS"
      subtitle: "What you are testing right now"
      description: "Active tests only. For each: hypothesis, method, current result, and exit condition. If there is no exit condition, it is not an experiment — it is an activity." }
    { key: ""  file: "Mastery.org"       label: "MASTERY"
      subtitle: "What you can actually do"
      description: "Honest self-assessment per skill. What is internalized versus what is surface familiarity. Distinguish between knowing something and being able to execute it under pressure." }
    { key: ""  file: "Sources.org"       label: "SOURCES"
      subtitle: "What is worth returning to"
      description: "Books, papers, people, and repositories that have proven reliable. Vetted only — no speculative bookmarks. If you have not returned to it, it does not belong here yet." }
    { key: "t"  file: "TODO.org"         label: "TODO"
      subtitle: "What is unfinished and consuming attention"
      description: "A ledger of open, executable items. No speculation, no someday-maybe. If it is on this list, it is active. If it is not executable, it belongs in Hypotheses or Blueprint." }
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
                let keyword = if ($content | str starts-with "TODO ") { "TODO" } else if ($content | str starts-with "DONE ") { "DONE" } else if ($content | str starts-with "IN-PROGRESS ") { "IN-PROGRESS" } else { "" }
                let clean = if ($keyword | is-not-empty) { $content | str replace -r '^(TODO|DONE|IN-PROGRESS) ' "" } else { $content }
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

# =============================================================================
# PRINT SECTION
# =============================================================================
def print-section [path: string, label: string, subtitle: string, description: string] {
    if ($path | path exists) {
        let rows = (parse-org $path)
        let count = ($rows | length)
        let status = if $count > 0 { $"● ($count)" } else { "○ empty" }
        print ""
        print $"(ansi red_bold)  🌹 ($label) 🌹 ($subtitle) 🌹 ($status)(ansi reset)"
        print $"  🌹 ($description)"
        if $count > 0 {
            print ""
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
# WORKSPACE DRAW
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
    print $"(ansi grey)  🌹 \"To choose is to affirm, by your choice, the weight of your own existence.(ansi reset)"
    print $"(ansi grey)     You are condemned to be free.\" — Jean-Paul Sartre 🌹(ansi reset)"
    print ""
    for entry in $WORKSPACE {
        if $entry.file != "TODO.org" {
            print-section ($env.PWD | path join $entry.file) $entry.label $entry.subtitle $entry.description
        }
    }
    print ""
    repo-status-line
    print ""
    print-section ($env.PWD | path join "TODO.org") "TODO" "What is unfinished and consuming attention" "A ledger of open, executable items. No speculation, no someday-maybe. If it is on this list, it is active. If it is not executable, it belongs in Hypotheses or Blueprint."
    print ""
}

# =============================================================================
# COMMANDS OVERLAY
# =============================================================================
def show-commands [] {
    clear
    print ""
    print $"(ansi red_bold)  🌹 COMMANDS(ansi reset)"
    print ""
    $COMMANDS | table | print
    print ""
}

# =============================================================================
# JJ
# =============================================================================
def jj-describe [] {
    try {
        let current = (do { jj log --no-graph -r '@' --template 'description' } | complete | get stdout | str trim)
        if ($current | is-not-empty) {
            print $"(ansi grey)  current: ($current)(ansi reset)"
        }
        print -n $"(ansi purple)  Description: (ansi reset)"
        let msg = (input "" | str trim)
        if ($msg | is-empty) {
            print $"(ansi grey)  — no change(ansi reset)"
            return
        }
        do { jj describe -m $msg } | complete | null
        print $"(ansi green)  ✓ described: ($msg)(ansi reset)"
    } catch {
        print $"(ansi red)  ✗ jj describe failed(ansi reset)"
    }
}

def jj-push-confirmed [] {
    let status = (do { jj status } | complete | get stdout | str trim)
    let log    = (do { jj log --no-graph -r '@' } | complete | get stdout | str trim)
    print ""
    print $"(ansi red_bold)  🌹 PENDING(ansi reset)"
    print $log
    if ($status | is-not-empty) {
        print ""
        print $status
    }
    print ""
    print -n $"(ansi purple)  Push? [y/N]: (ansi reset)"
    let ans = (input "" | str trim | str downcase)
    if $ans == "y" {
        ManifoldOS-Reshaping-History
        print $"(ansi green)  ✓ pushed(ansi reset)"
    } else {
        print $"(ansi grey)  — cancelled(ansi reset)"
    }
}

# =============================================================================
# QUICK CAPTURE
# =============================================================================
def quick-capture [] {
    let todo_path = ($env.PWD | path join "TODO.org")
    print -n $"(ansi purple)  New TODO: (ansi reset)"
    let text = (input "" | str trim)
    if ($text | is-not-empty) {
        $"\n* TODO ($text)" | save --append $todo_path
        print $"(ansi green)  ✓ ($text)(ansi reset)"
    } else {
        print $"(ansi grey)  — nothing captured(ansi reset)"
    }
}

# =============================================================================
# TODO STATE TRANSITIONS
# =============================================================================
def progress-last [] {
    let todo_path = ($env.PWD | path join "TODO.org")
    if not ($todo_path | path exists) {
        print $"(ansi grey)  — TODO.org not found(ansi reset)"
        return
    }
    let lines = (open --raw $todo_path | lines)
    let last_todo = (
        $lines | enumerate | reverse
        | where { |e| $e.item | str starts-with "* TODO " }
        | get 0?
    )
    if ($last_todo | is-empty) {
        print $"(ansi grey)  — no TODO items found(ansi reset)"
        return
    }
    let idx = $last_todo.index
    let toggled = ($lines | get $idx | str replace "* TODO " "* IN-PROGRESS ")
    let updated = ($lines | enumerate | each { |e| if $e.index == $idx { $toggled } else { $e.item } })
    $updated | str join "\n" | save --force $todo_path
    let label = ($toggled | str replace "* IN-PROGRESS " "")
    print $"(ansi yellow)  ◎ in progress: ($label)(ansi reset)"
}

def done-last [] {
    let todo_path = ($env.PWD | path join "TODO.org")
    if not ($todo_path | path exists) {
        print $"(ansi grey)  — TODO.org not found(ansi reset)"
        return
    }
    let lines = (open --raw $todo_path | lines)
    let last_active = (
        $lines | enumerate | reverse
        | where { |e| ($e.item | str starts-with "* TODO ") or ($e.item | str starts-with "* IN-PROGRESS ") }
        | get 0?
    )
    if ($last_active | is-empty) {
        print $"(ansi grey)  — no active items found(ansi reset)"
        return
    }
    let idx = $last_active.index
    let toggled = ($lines | get $idx | str replace -r '^\* (TODO|IN-PROGRESS) ' "* DONE ")
    let updated = ($lines | enumerate | each { |e| if $e.index == $idx { $toggled } else { $e.item } })
    $updated | str join "\n" | save --force $todo_path
    let label = ($toggled | str replace "* DONE " "")
    print $"(ansi green)  ✓ done: ($label)(ansi reset)"
}

def delete-last [] {
    let todo_path = ($env.PWD | path join "TODO.org")
    if not ($todo_path | path exists) {
        print $"(ansi grey)  — TODO.org not found(ansi reset)"
        return
    }
    let lines = (open --raw $todo_path | lines)
    let last_done = (
        $lines | enumerate | reverse
        | where { |e| $e.item | str starts-with "* DONE " }
        | get 0?
    )
    if ($last_done | is-empty) {
        print $"(ansi grey)  — no DONE items to delete (mark done first)(ansi reset)"
        return
    }
    let idx = $last_done.index
    let label = ($lines | get $idx | str replace "* DONE " "")
    let updated = ($lines | enumerate | where { |e| $e.index != $idx } | get item)
    $updated | str join "\n" | save --force $todo_path
    print $"(ansi red)  ✗ deleted: ($label)(ansi reset)"
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
                "p" => { progress-last }
                "s" => { done-last }
                "d" => { delete-last }
                "u" => { fzf-open }
                "h" => { fzf-bat; $needs_draw = false }
                "i" => { jj-describe; $needs_draw = false }
                "m" => { show-commands; $needs_draw = false }
                "w" => { ManifoldOS-Weather; $needs_draw = false }
                "g" => {
                    jj-push-confirmed
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