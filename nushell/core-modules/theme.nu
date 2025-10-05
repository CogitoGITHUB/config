let dark_theme = {
    # color for nushell primitives
    separator: white
    leading_trailing_space_bg: { attr: n } # no fg, no bg, attr none effectively turns this off
    header: white
    empty: white
    # Closures can be used to choose colors for specific values.
    # The value (in this case, a bool) is piped into the closure.
    # eg) {|| if $in { 'light_cyan' } else { 'light_gray' } }
    bool: white
    int: white
    filesize: white
    duration: white
    date: white
    range: white
    float: white
    string: white
    nothing: white
    binary: white
    cell-path: white
    row_index: white
    record: white
    list: white
    block: white
    hints: white
    search_result: { bg: grey fg: white }
    shape_and: white
    shape_binary: white
    shape_block: white
    shape_bool: white
    shape_closure: white
    shape_custom: white
    shape_datetime: white
    shape_directory: white
    shape_external: white
    shape_externalarg:white
    shape_external_resolved: white
    shape_filepath: white
    shape_flag: white
    shape_float: white
    # shapes are used to change the cli syntax highlighting
    shape_garbage: { fg: white bg: red attr: b }
    shape_glob_interpolation: white
    shape_globpattern: white
    shape_int: white
    shape_internalcall: white
    shape_keyword: white
    shape_list: white
    shape_literal: white
    shape_match_pattern: white
    shape_matching_brackets: { attr: u }
    shape_nothing: white
    shape_operator: white
    shape_or: white
    shape_pipe: white
    shape_range: white
    shape_record: white
    shape_redirection: white
    shape_signature: white
    shape_string: white
    shape_string_interpolation: white
    shape_table: white
    shape_variable: white
    shape_vardecl: white
    shape_raw_string: white
}
let color_config = $dark_theme


mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
