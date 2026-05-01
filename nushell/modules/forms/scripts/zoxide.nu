def --env --wrapped __zoxide_z [...rest: string] {
    let path = match $rest {
        []      => { '~' },
        [ '-' ] => { '-' },
        [ $arg ] if ($arg | path type) == 'dir' => { $arg }
        _ => {
            let result = (do { zoxide query --exclude $env.PWD -- ...$rest } | complete)
            if $result.exit_code == 0 { $result.stdout | str trim } else { $rest | str join " " }
        }
    }
    cd $path
    $env.__skip_workspace = false
    maybe-open-todo
}

def --env __zoxide_zi [...rest: string] {
    let sel = (try {
        zoxide query --list
        | to text
        | fzf --height=40% --reverse --no-preview
    } catch { "" })
    if ($sel | str trim) != "" {
        cd ($sel | str trim)
        $env.__skip_workspace = false
        maybe-open-todo
    }
}

alias z  = __zoxide_z
alias zi = __zoxide_zi