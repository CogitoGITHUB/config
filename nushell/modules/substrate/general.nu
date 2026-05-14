# The default config record. This is where much of your global configuration is setup.
$env.config = {
    show_banner: false

    ls: {
        use_ls_colors: false
        clickable_links: true
    }

    rm: {
        always_trash: true
    }

    table: {
        mode: rounded
        index_mode: auto
        show_empty: true
        padding: { left: 0, right: 0 }
        trim: {
            methodology: wrapping
            wrapping_try_keep_words: true
            truncating_suffix: "..."
        }
        header_on_separator: true
        footer_inheritance: true
    }

    error_style: "fancy"

    display_errors: {
        exit_code: true
        termination_signal: true
    }

    datetime_format: {
        table: '%m/%d/%y %I:%M:%S%p'
    }

    explore: {
        status_bar_background: { fg: "#8B0000", bg: "#3D0000" }
        command_bar_text: { fg: "#8B0000" }
        highlight: { fg: "#8B0000", bg: "#3D0000" }
        status: {
            error: { fg: "#8B0000", bg: "#3D0000" }
            warn: { fg: "#8B0000", bg: "#3D0000" }
            info: { fg: "#8B0000", bg: "#3D0000" }
        }
        selected_cell: { bg: "#3D0000" }
    }

    history: {
        max_size: 100_000
        sync_on_enter: true
        file_format: "sqlite"
        isolation: false
    }

    cursor_shape: {
        emacs: line
        vi_insert: block
        vi_normal: underscore
    }

    footer_mode: 25
    float_precision: 2
    buffer_editor: null
    use_ansi_coloring: true
    bracketed_paste: true
    edit_mode: vi

    shell_integration: {
        osc2: true
        osc7: true
        osc8: true
        osc9_9: true
        osc133: true
        osc633: true
        reset_application_mode: true
    }

    render_right_prompt_on_last_line: false
    use_kitty_protocol: false
    highlight_resolved_externals: false
    recursion_limit: 50

    hooks: {
        pre_prompt: [{ null }]
        pre_execution: [{ null }]
        env_change: {
            PWD: [{|before, after| null }]
        }
        display_output: "if (term size).columns >= 100 { table -e } else { table }"
        command_not_found: { null }
    }

    menus: [
        {
            name: completion_menu
            only_buffer_difference: false
            marker: "| "
            type: {
                layout: columnar
                columns: 4
                col_width: 20
                col_padding: 2
            }
            style: {
                text: dark_red
                selected_text: { fg: dark_red, bg: "#3D0000" }
                description_text: dark_red
                match_text: { attr: u }
                selected_match_text: { fg: dark_red, bg: "#3D0000" }
            }
        }
        {
            name: ide_completion_menu
            only_buffer_difference: false
            marker: "| "
            type: {
                layout: ide
                min_completion_width: 0
                max_completion_width: 50
                max_completion_height: 10
                padding: 0
                border: true
                cursor_offset: 0
                description_mode: "prefer_right"
                min_description_width: 0
                max_description_width: 50
                max_description_height: 10
                description_offset: 1
                correct_cursor_pos: false
            }
            style: {
                text: dark_red
                selected_text: { fg: dark_red, bg: "#3D0000" }
                description_text: dark_red
                match_text: { attr: u }
                selected_match_text: { fg: dark_red, bg: "#3D0000" }
            }
        }
        {
            name: history_menu
            only_buffer_difference: true
            marker: "? "
            type: {
                layout: list
                page_size: 10
            }
            style: {
                text: dark_red
                selected_text: { fg: dark_red, bg: "#3D0000" }
                description_text: dark_red
            }
        }
        {
            name: help_menu
            only_buffer_difference: true
            marker: "? "
            type: {
                layout: description
                columns: 4
                col_width: 20
                col_padding: 2
                selection_rows: 4
                description_rows: 10
            }
            style: {
                text: dark_red
                selected_text: { fg: dark_red, bg: "#3D0000" }
                description_text: dark_red
            }
        }
    ]
}