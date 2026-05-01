hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "dvorak",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll       = true,
            ["tap-to-click"]     = true,
            clickfinger_behavior = true,
            disable_while_typing = true,
            scroll_factor        = 0.6,
        },
    },

    -- ── Gesture physics ────────────────────────────────────────────────
    gestures = {
        workspace_swipe_distance     = 400,
        workspace_swipe_invert       = true,
        workspace_swipe_cancel_ratio = 0.3,
    },
})