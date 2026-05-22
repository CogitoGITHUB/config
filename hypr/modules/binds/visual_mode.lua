hl.define_submap("Visual", function()
    -- Move Focus
    hl.bind("H", hl.dsp.focus({ direction = "left" }))
    hl.bind("L", hl.dsp.focus({ direction = "right" }))
    hl.bind("J", hl.dsp.focus({ direction = "down" }))
    hl.bind("K", hl.dsp.focus({ direction = "up" }))

    -- Scroll through existing workspaces with mainMod + scroll
    hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "m+1" }))
    hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "m-1" }))
    for key = 1, 8 do
        hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = key }))
        hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = key }))
    end

    -- Resize
    hl.bind("+", hl.dsp.layout("colresize 1"))
    hl.bind("MINUS", hl.dsp.layout("colresize 0.5"))

    hl.bind("E", hl.dsp.layout('expel'))

    hl.bind("D", hl.dsp.window.close())
    hl.bind("F", hl.dsp.window.fullscreen())

    hl.bind("SUPER + V", hl.dsp.submap("Visual"))
    hl.bind("SUPER + I", hl.dsp.submap("Insert"))
    hl.bind("SUPER + C", hl.dsp.submap("Normal"))
end)