source ~/.config/nushell/modules/forms/scripts/ManifoldOS-Sources.nu

def mb-flow [current: string, timings: record] {
    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // BUILD 🌹(ansi reset)"
    print ""
    for step in ["Cache" "Build"] {
        let elapsed   = ($timings | get -o $step | default "")
        let is_done   = ($elapsed | is-not-empty)
        let is_active = ($step == $current)
        let symbol    = if $is_done and not $is_active { "🌹" } else if $is_active { "►" } else { "○" }
        let suffix    = if $is_active { "───► running" } else if $is_done { $"✓  ($elapsed)" } else { "" }
        print $"  ($symbol)  ($step)  ($suffix)"
    }
    print ""
}

def ManifoldOS-Build [] {
    let origin = ($env.PWD)
    let log    = $"/tmp/manifold_build_(date now | format date '%Y%m%d_%H%M%S').log"
    mut timing = {}

    ManifoldOS-Sources

    mb-flow "Cache" $timing
    let t = (date now)
    try { rm -rf ~/.cache/guile/ccache out+err>> $log } catch { }
    try { ^/run/setuid-programs/sudo rm -rf /root/.cache/guile/ccache out+err>> $log } catch { }
    $timing = ($timing | insert Cache $"(((date now) - $t) / 1sec | math round)s")

    mb-flow "Build" $timing
    let t = (date now)
    let r = (^/run/setuid-programs/sudo guix system build /ManifoldOS/Manifold/constitution.scm | complete)
    $r.stdout out>> $log
    $r.stderr out>> $log
    $timing = ($timing | insert Build $"(((date now) - $t) / 1sec | math round)s")

    let output = ($r.stdout + "\n" + $r.stderr)
    let total  = (($timing | values) | each { |v| $v | str replace -r 's$' '' | into float } | math sum | math round --precision 1)

    print -n "\e[2J\e[H"
    print ""

    if $r.exit_code != 0 {
        print $"(ansi red_bold)🌹 MANIFOLD // BUILD — FAILED  ($total)s(ansi reset)"
        print ""
        $output | lines | where { |l| $l =~ "constitution:|error:" } | each { |l| print $"  ($l | str trim)" }
        print ""
        print $"(ansi grey)📋 ($log)(ansi reset)"
    } else {
        print $"(ansi green_bold)🌹 MANIFOLD // BUILD — OK  ($total)s(ansi reset)"
        print ""
        $output | lines | where { |l| $l =~ "constitution: scanned" } | last 1 | each { |l| print $"  ($l | str trim)" }
        print ""
        $output | lines | where { |l| $l =~ "WARNING:" } | each { |l| print $"(ansi yellow)  ($l | str trim)(ansi reset)" }
        print $"(ansi grey)📋 ($log)(ansi reset)"
    }

    print ""
    cd $origin
}

$env.config.keybindings = ($env.config.keybindings | append {
    name: ManifoldOS_Build
    modifier: control
    keycode: char_b
    mode: emacs
    event: { send: executehostcommand cmd: "ManifoldOS-Build" }
})