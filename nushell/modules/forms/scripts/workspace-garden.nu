# =============================================================================
# FZF
# =============================================================================
def fzf-open [path?: string] {
    let root = ($path | default ".")
    let file = (^bash -c $"fd --type f . '($root)' | fzf --preview 'bat --color=always --style=numbers {}' --preview-window 'right:60%:wrap' --prompt '  File> ' --header 'ENTER to open in emacs'" | str trim)
    if not ($file | is-empty) { ^emacsclient $file }
}

def fzf-bat [path?: string] {
    let root = ($path | default ".")
    let file = (^bash -c $"fd --type f . '($root)' | fzf --preview 'bat --color=always --style=numbers {}' --preview-window 'right:60%:wrap' --prompt '  File> ' --header 'ENTER to view in bat'" | str trim)
    if not ($file | is-empty) { ^bat --style=full --color=always $file }
}

# =============================================================================
# 🌹 COMMANDS 🌹
# =============================================================================
const COMMANDS = [
    { key: "w",  command: "Weather" }
    { key: "n",  command: "Capture" }
    { key: "p",  command: "In Progress (last TODO)" }
    { key: "s",  command: "Done (last active)" }
    { key: "d",  command: "Delete (last DONE only)" }
    { key: "u",  command: "fzf > emacs" }
    { key: "h",  command: "fzf > bat" }
    { key: "v",  command: "jj diff" }
    { key: "i",  command: "jj describe" }
    { key: "g",  command: "jj push" }
    { key: "m",  command: "Commands" }
    { key: "r",  command: "Redraw" }
    { key: "l",  command: "Clear" }
    { key: " ",  command: "Exit" }
]

# =============================================================================
# WORKSPACE CONFIG
# =============================================================================
const WORKSPACE = [
    { key: ""  file: "ShapeShifter.org"  label: "SHAPESHIFTER"
      subtitle: "Which version is deployed"
      description: "The active configuration of the Architect in this workspace. Declares which ShapeShifter is instantiated, its scope, its behavioral parameters, and — critically — its withdrawal condition. If there is no withdrawal condition, this is not a deployment. It is a drift." }
    { key: ""  file: "Objectives.org"    label: "OBJECTIVES"
      subtitle: "What the ShapeShifter is actually pursuing"
      description: "Strategic outcomes. Not tasks, not actions — the results whose existence would confirm the deployment succeeded. Each objective should be falsifiable. If you cannot tell when it is achieved, it is not an objective. It is a direction." }
    { key: ""  file: "Map.org"           label: "MAP"
      subtitle: "Where this workspace sits in the whole"
      description: "The position of this workspace inside Cartesia. What feeds into it, what it feeds into, which domains it touches, which ShapeShifters it has supported. A workspace without a map is isolated. Isolation is drift with a different name." }
    { key: ""  file: "Agents.org"        label: "AGENTS"
      subtitle: "Who is in play"
      description: "Actors, roles, and contacts relevant to this deployment. Their interests, capabilities, and relationship to your position. The Architect does not engage people directly — ShapeShifters do. This file informs how they are configured for that contact." }
    { key: ""  file: "Blueprint.org"     label: "BLUEPRINT"
      subtitle: "How it is built"
      description: "The load-bearing architecture of what is being constructed. Not goals — design decisions. The structure that, if changed, forces everything downstream to change with it. The Architect authors this. The ShapeShifter executes against it." }
    { key: ""  file: "Rules.org"         label: "RULES"
      subtitle: "What constrains action"
      description: "Self-defined boundaries and imposed constraints that structure this deployment and reduce variance. Some are chosen by the Architect. Some are external and non-negotiable. Know which is which — confusing authored constraints with imposed ones is an expensive failure mode." }
    { key: ""  file: "Journal.org"       label: "JOURNAL"
      subtitle: "What actually happened"
      description: "Stripped observations only. Events, deviations, reactions — no interpretation at write time. The ShapeShifter reports here. The Architect reads later. If you are editorializing while writing, you are corrupting the input before it reaches analysis." }
    { key: ""  file: "Context.org"       label: "CONTEXT"
      subtitle: "The conditions shaping outcomes"
      description: "The operational environment this ShapeShifter was deployed into. Timing, dependencies, pressures, and constraints you did not choose. The same move produces different results in different context. This file explains why the output was what it was." }
    { key: ""  file: "State.org"         label: "STATE"
      subtitle: "Where things actually stand"
      description: "Current-state register. What exists, what is complete, what is degraded, what is blocked. A live contrast between the Blueprint and reality. If this file is optimistic, it is lying to the Architect. The Architect designs against truth, not comfort." }
    { key: ""  file: "Laws.org"          label: "LAWS"
      subtitle: "What is enforceable"
      description: "Codified legal reality within the relevant jurisdiction. External, indifferent to intent, and non-negotiable. The Architect maps the hard walls before designing in the gray zones. Ignorance of this layer is not a ShapeShifter failure — it is an architecture failure." }
    { key: ""  file: "Philosophy.org"    label: "PHILOSOPHY"
      subtitle: "Why any of this is authorized"
      description: "The foundational reasoning that authorizes this deployment and defines what the Architect is willing to do. Not preference — principle. If this fails under scrutiny, every decision above it becomes noise. Revisit it when drift is felt." }
    { key: ""  file: "Decisions.org"     label: "DECISIONS"
      subtitle: "What the Architect has already chosen"
      description: "A permanent log of consequential decisions made in this workspace, with their reasoning preserved at the time of choice. The ShapeShifter executes. The Architect decides. This file is what separates design from reaction when you return six months later and need to know why." }
    { key: ""  file: "Advantages.org"    label: "ADVANTAGES"
      subtitle: "What you have that others do not"
      description: "Structural edges, asymmetries, and positional strengths that increase the probability of success in this deployment. Honest inventory only — what is real versus what is flattering. The Architect builds on actual advantages, not imagined ones." }
    { key: ""  file: "Leverage.org"      label: "LEVERAGE"
      subtitle: "What moves people and systems"
      description: "Time-sensitive pressure points, information asymmetries, favors owed, and dependency windows that give disproportionate influence. Unlike Advantages, leverage expires. The Architect tracks when and how — an unused window is an authored failure." }
    { key: ""  file: "Counters.org"      label: "COUNTERS"
      subtitle: "How this deployment could be beaten"
      description: "Adversarial defense. The moves others could make against this position, and the pre-built responses. The Architect thinks like the opposition before the ShapeShifter is deployed. A position without mapped counters is not a design — it is a hope." }
    { key: ""  file: "Signals.org"       label: "SIGNALS"
      subtitle: "What the environment is telling you now"
      description: "Live leading indicators being actively watched. Not evidence — retrospective. Not hypotheses — open questions. Signals are inputs arriving now that may become either. The ShapeShifter surfaces them. The Architect decides their weight." }
    { key: ""  file: "Timing.org"        label: "TIMING"
      subtitle: "When things open and close"
      description: "Windows, deadlines, decay rates, and expiration of conditions. Most deployment failures are timing failures, not logic failures. The Architect tracks when opportunities close, when leverage expires, and when the environment shifts beneath the ShapeShifter." }
    { key: ""  file: "Quotes.org"        label: "QUOTES"
      subtitle: "Compressed precision"
      description: "Language retained because it resists paraphrase without loss. Statements that remain true under scrutiny and still carry weight six months later. Not inspiration — compression. Every entry must earn its place against that standard." }
    { key: ""  file: "TrapsInternal.org" label: "TRAPS INTERNAL"
      subtitle: "How you fail yourself"
      description: "Known personal failure modes specific to this deployment context. Cognitive patterns, emotional triggers, and behavioral loops that have caused or will cause damage. Recognition in advance is the only viable defense. The Architect maps them here so the ShapeShifter does not fall into them." }
    { key: ""  file: "TrapsExternal.org" label: "TRAPS EXTERNAL"
      subtitle: "How you constrain others"
      description: "Traps authored for opposing actors. Positions, framings, and conditions that limit their options or force unfavorable moves. Built by the Architect, executed by the ShapeShifter. Constructed deliberately — never reactively." }
    { key: ""  file: "Failures.org"      label: "FAILURES"
      subtitle: "What did not work and exactly why"
      description: "Retrospective post-mortems only. Not predictions — records. What failed, the exact mechanism of failure, what it cost, and what the Architect updates as a result. Distinct from TrapsInternal, which is predictive. Failures are the receipts. They inform the next design." }
    { key: ""  file: "Evidence.org"      label: "EVIDENCE"
      subtitle: "What changed your mind"
      description: "Observations and data points that have materially updated the Architect's model. Not a fact repository — a record of epistemic shifts. Log what moved the design and why. A model that never updates is not the Architect thinking. It is the Architect frozen." }
    { key: ""  file: "Hypotheses.org"    label: "HYPOTHESES"
      subtitle: "What you are still working out"
      description: "Open uncertainties with enough structure to be tested. Not todos, not facts — live questions the Architect is actively pursuing. If a hypothesis has no path to resolution, it is speculation. Speculation belongs nowhere in this system." }
    { key: ""  file: "Experiments.org"   label: "EXPERIMENTS"
      subtitle: "What you are testing right now"
      description: "Active tests only. For each: hypothesis being tested, method, current result, and exit condition. The exit condition is non-negotiable. Without it, there is no experiment — there is only activity the Architect has mistaken for design." }
    { key: ""  file: "Mastery.org"       label: "MASTERY"
      subtitle: "What this ShapeShifter can actually do"
      description: "Honest capability assessment for this deployment context. What is internalized versus surface familiarity. The Architect does not deploy a ShapeShifter beyond its actual capability — only beyond its current one, as a deliberate growth mechanism." }
    { key: ""  file: "Sources.org"       label: "SOURCES"
      subtitle: "What is worth returning to"
      description: "Books, papers, people, and repositories that have proven reliable in this domain. Vetted only — no speculative bookmarks. If you have not returned to it, it does not belong here yet. The Architect curates. The ShapeShifter consumes." }
    { key: "t"  file: "TODO.org"         label: "TODO"
      subtitle: "What is unfinished and consuming attention"
      description: "A ledger of open, executable items assigned to the active ShapeShifter. No speculation, no someday-maybe. If it is on this list, it is active. If it is not executable, it belongs in Hypotheses or Blueprint. The Architect reviews this. The ShapeShifter executes it." }
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
        let rose = if $count > 0 { "🌹" } else { "🥀" }
        print ""
        print $"(ansi red_bold)  ($rose) ($label) ($rose) ($subtitle) ($rose) ($status)(ansi reset)"
        print $"  ($rose) ($description)"
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
    print-section ($env.PWD | path join "TODO.org") "TODO" "What is unfinished and consuming attention" "A ledger of open, executable items assigned to the active ShapeShifter. No speculation, no someday-maybe. If it is on this list, it is active. If it is not executable, it belongs in Hypotheses or Blueprint. The Architect reviews this. The ShapeShifter executes it."
    print ""
    workspace-health
    print ""
}

def workspace-health [] {
    let files = ($WORKSPACE | each {|e| $env.PWD | path join $e.file})
    let total = ($files | length)
    let alive = ($files | where {|p|
        ($p | path exists) and ((open --raw $p | str trim | is-not-empty))
    } | length)
    let dead = $total - $alive
    let roses = (0..$alive | each { "🌹" } | str join "")
    let wilted = (0..$dead | each { "🥀" } | str join "")
    let bar = $"($roses)($wilted)"
    let msg = if $dead == $total {
        "The garden is barren. The Architect has not yet begun."
    } else if $dead >= ($total / 2 | math floor) {
        "The deployment is thin. Most shapes are empty."
    } else if $dead > 0 {
        "Most shapes hold. Some still hunger for input."
    } else {
        "The garden is tended. Every shape is alive."
    }
    print $"  ($bar)"
    print $"(ansi grey)  ($msg)(ansi reset)"
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
def jj-diff [] {
    ^bash -c "jj diff | bat --style=full --color=always --language=diff"
}

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
    let ans = (input "" | str trim | str lowercase)
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
                "v" => { jj-diff; $needs_draw = false }
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
                    print-section ($env.PWD | path join "TODO.org") "TODO" "What is unfinished and consuming attention" "A ledger of open, executable items assigned to the active ShapeShifter. No speculation, no someday-maybe. If it is on this list, it is active. If it is not executable, it belongs in Hypotheses or Blueprint. The Architect reviews this. The ShapeShifter executes it."
                    print ""
                    workspace-health
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
    if ($env | get -o __skip_workspace) == true {
        $env.__skip_workspace = false
        return
    }
    ensure-workspace-files
    workspace-loop
}

export def show-dir-info [] {
    draw-workspace
}