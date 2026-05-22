hl.define_submap("Insert", function()
    hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })

    for key = 1, 8 do
        hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = key }))
        hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = key }))
    end

    -- Scroll through existing workspaces with mainMod + scroll
    hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "m+1" }))
    hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "m-1" }))

    hl.bind("SUPER + C", hl.dsp.submap("Normal"))
end)