local command_mode = require("modules.binds.command_mode")

hl.bind("SUPER + C", hl.dsp.submap("Normal"))

hl.define_submap("Normal", function()
    -- move focus
    hl.bind("H", hl.dsp.focus({ direction = "left" }))
    hl.bind("T", hl.dsp.focus({ direction = "right" }))
    hl.bind("N", hl.dsp.focus({ direction = "down" }))
    hl.bind("S", hl.dsp.focus({ direction = "up" }))

    -- Scroll through existing workspaces with mainMod + scroll
    hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "m+1" }))
    hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "m-1" }))
    for key = 1, 8 do
        hl.bind("" .. key, hl.dsp.focus({ workspace = key }))
        hl.bind("SHIFT + " .. key, hl.dsp.window.move({ workspace = key }))
    end

    -- Open
    local menu = "rofi -show drun"
    hl.bind("O", function()
        hl.dispatch(hl.dsp.submap("Insert"))
        hl.dispatch(hl.dsp.exec_cmd(menu))
    end)

    hl.bind("SHIFT + D", hl.dsp.window.close())
    hl.bind("F", hl.dsp.window.fullscreen())

    hl.bind("N", hl.dsp.focus({ workspace = "m+1", on_current_monitor = true }))

    hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })

    hl.bind("I", hl.dsp.submap("Insert"))
    hl.bind("SUPER + I", hl.dsp.submap("Insert"))

    hl.bind("V", hl.dsp.submap("Visual"))
    hl.bind("SUPER + V", hl.dsp.submap("Visual"))


    hl.bind("SHIFT + SEMICOLON", function()
        command_mode.bufferopen()
    end)

    local draw = "waypai toggle"
    local draw_freeze = "waypai freeze"
    hl.bind("SUPER + D", hl.dsp.exec_cmd(draw))
    hl.bind("SUPER + F", hl.dsp.exec_cmd(draw_freeze))

    hl.bind("SUPER + C", hl.dsp.submap("Normal"))
end)