export def parse-org [org_path: string] {
    open $org_path
    | lines
    | each {|line|
        try {
            let level = ($line | parse -r '^(\*+) ' | get capture0.0? | default "" | str length)
            if $level > 0 {
                let content = ($line | str replace -r '^\*+ ' "")
                if ($content | str starts-with "http") {
                    {level: $level, kind: "link", description: $content}
                } else {
                    {level: $level, kind: "task", description: $content}
                }
            } else { null }
        } catch { null }
    }
    | compact
}

def print-section [path: string, label: string, subtitle: string] {
    if ($path | path exists) {
        let rows = (parse-org $path)
        print ""
        print $"(ansi red_bold)  ($label)(ansi reset)"
        print $"(ansi grey)  ($subtitle)(ansi reset)"
        if ($rows | length) > 0 {
            $rows | print
        } else {
            print $"(ansi grey)  —(ansi reset)"
        }
    }
}

def ensure-workspace-files [] {
    let files = [
        "Agents.org" "Blueprint.org" "Rules.org" "TODO.org"
        "Journal.org" "Context.org" "State.org" "Laws.org"
        "Philosophy.org" "Advantages.org" "Quotes.org"
        "Principles.org" "TrapsInternal.org" "TrapsExternal.org"
    ]
    for name in $files {
        let fpath = ($env.PWD | path join $name)
        if not ($fpath | path exists) {
            sudo touch $fpath
        }
    }
}

def draw-workspace [] {
    let dir_name = ($env.PWD | path basename)
    print ""
    print ($env.PWD | path split)
    print $"(ansi red_bold)  ($dir_name)(ansi reset)"
    ls -la | reject inode target num_links | print
    print-section ($env.PWD | path join "TODO.org")          "TODO"            "a ledger of unfinished business. No speculation. Only executable items that remain open and consume attention."
    print-section ($env.PWD | path join "Journal.org")       "JOURNAL"         "stripped observations. Events, reactions, deviations. No storytelling, only what can be examined later."
    print-section ($env.PWD | path join "State.org")         "STATE"           "a current-state register. What exists, what's complete, what's degraded. A contrast between intent and reality."
    print-section ($env.PWD | path join "Laws.org")          "LAWS"            "codified legal reality. Statutes, regulations, and case law within the relevant jurisdiction. Enforceable, external, indifferent to intent."
    print-section ($env.PWD | path join "Rules.org")         "RULES"           "imposed constraints. Self-defined boundaries that structure action and reduce variance. Optional, but costly to ignore."
    print-section ($env.PWD | path join "Context.org")       "CONTEXT"         "operational surroundings. Timing, environment, dependencies, pressures. The conditions that shape outcomes."
    print-section ($env.PWD | path join "Philosophy.org")    "PHILOSOPHY"      "foundational logic. The reasoning that justifies action. If this fails, the rest becomes noise."
    print-section ($env.PWD | path join "Advantages.org")    "ADVANTAGES"      "leverage inventory. Structural edges, asymmetries, resources that increase probability of success."
    print-section ($env.PWD | path join "Quotes.org")        "QUOTES"          "compressed statements. Language retained for precision and recall. Only what remains accurate under scrutiny."
    print-section ($env.PWD | path join "TrapsInternal.org") "TRAPS INTERNAL"  "known failure modes. Patterns that have caused or will cause damage. Recognized in advance, not in retrospect."
    print-section ($env.PWD | path join "TrapsExternal.org") "TRAPS EXTERNAL"  "traps constructed for others. Positions, framings, and conditions that constrain opposing action."
    print ""
    print ""
}

def workspace-with-prompt [] {
    draw-workspace
    print $"(ansi purple)  [a] Agents  [o] Blueprint  [e] Rules  [u] TODO  [i] Journal  [d] Context  [h] State  [t] Laws  [p] Philosophy  [v] Advantages  [q] Quotes  [x] Traps Internal  [y] Traps External  [space] skip(ansi reset)"

    let code = (try { input listen --types [key] } catch { {code: "escape"} }).code

    match $code {
        "a" => { emacs ($env.PWD | path join "Agents.org");        workspace-with-prompt }
        "o" => { emacs ($env.PWD | path join "Blueprint.org");     workspace-with-prompt }
        "e" => { emacs ($env.PWD | path join "Rules.org");         workspace-with-prompt }
        "u" => { emacs ($env.PWD | path join "TODO.org");          workspace-with-prompt }
        "i" => { emacs ($env.PWD | path join "Journal.org");       workspace-with-prompt }
        "d" => { emacs ($env.PWD | path join "Context.org");       workspace-with-prompt }
        "h" => { emacs ($env.PWD | path join "State.org");         workspace-with-prompt }
        "t" => { emacs ($env.PWD | path join "Laws.org");          workspace-with-prompt }
        "p" => { emacs ($env.PWD | path join "Philosophy.org");    workspace-with-prompt }
        "v" => { emacs ($env.PWD | path join "Advantages.org");    workspace-with-prompt }
        "q" => { emacs ($env.PWD | path join "Quotes.org");        workspace-with-prompt }
        "x" => { emacs ($env.PWD | path join "TrapsInternal.org"); workspace-with-prompt }
        "y" => { emacs ($env.PWD | path join "TrapsExternal.org"); workspace-with-prompt }
        _ => {
            draw-workspace
            print $"(ansi red_bold)  🌹 Reshaping is only adaptation under pressure 🌹(ansi reset)"
            print ""
            print ""
            $env.__skip_workspace = true
        }
    }
}

export def maybe-open-todo [] {
    if ($env | get -i __skip_workspace) == true {
        $env.__skip_workspace = false
        return
    }
    ensure-workspace-files
    workspace-with-prompt
}

export def show-dir-info [] {
    draw-workspace
}