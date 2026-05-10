hl.config({
    scrolling = {
        focus_fit_method          = 0,  -- 0 = center, 1 = fit
        follow_focus              = true,
        fullscreen_on_one_column  = true,
        column_width              = 0.5,
    },
})

-- Workaround: center on mouse click focus
hl.on("window.active", function(w)
    hl.dispatch(hl.dsp.layout("move +col"))
    hl.dispatch(hl.dsp.layout("move -col"))
end)