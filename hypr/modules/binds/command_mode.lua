local Module = {}
local buf = ""
local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
local active = false

local function screenshot(mode)
    local screenshot_time = os.date("%Y%m%d%H%M%S")

    hl.dispatch(hl.dsp.exec_cmd("hyprshot --freeze --mode " ..
        mode .. " --output-folder ~/Pictures/screenshots --filename " ..
        screenshot_time .. ".png"))
end


local command_handlers = {
    ["rl"] = function() hl.dispatch(hl.dsp.hyprland.reload()) end,

    ["q"] = function() hl.dispatch(hl.dsp.window.close()) end,
    ["qa"] = function() hl.dispatch(hl.dsp.workspace.close()) end,
    ["ej"] = function() hl.dispatch(hl.dsp.layout("expel")) end,

    ["wq"] = function() hl.dispatch(hl.dsp.exec_cmd("pidof wlogout || wlogout -b 4 -L 200 -R 200 -T 375 -B 375")) end,
    ["logout"] = function() hl.dispatch(hl.dsp.exec_cmd("pidof wlogout || wlogout -b 4 -L 200 -R 200 -T 375 -B 375")) end,
    ["shutdown"] = function() hl.dispatch(hl.dsp.exec_cmd("systemctl poweroff")) end,

    ["pick"] = function() hl.dispatch(hl.dsp.exec_cmd("pidof hyprpicker || hyprpicker | wl-copy")) end,

    ["draw"] = function() hl.dispatch(hl.dsp.exec_cmd("waypai toggle")) end,
    ["freezdrawing"] = function() hl.dispatch(hl.dsp.exec_cmd("waypai toggle")) end,

    ["r"] = function() hl.dispatch(hl.dsp.exec_cmd("rofi -show drun")) end,
    ["rofi"] = function() hl.dispatch(hl.dsp.exec_cmd("rofi -show drun")) end,

    ["fs"] = function() hl.dispatch(hl.dsp.exec_cmd("dolphin")) end,
    ["files"] = function() hl.dispatch(hl.dsp.exec_cmd("dolphin")) end,

    ["term"] = function() hl.dispatch(hl.dsp.exec_cmd("wezterm")) end,
    ["clip"] = function() hl.dispatch(hl.dsp.exec_cmd("cursor-clip")) end,
    ["fl"] = function() hl.dispatch(hl.dsp.window.fullscreen({ "fullscreen", "toggle" })) end,
    -- ["mv"] = function() hl.dispatch(hl.dsp.window.move({ workspace = "e+1" })) end,
    ["smol"] = function() hl.dispatch(hl.dsp.layout("colresize 0.5")) end,
    ["big"] = function() hl.dispatch(hl.dsp.layout("colresize 1.0")) end,

    ["z"] = function() hl.config({ general = { gaps_in = 0, gaps_out = 0, border_size = 0 }, decoration = { blur = { enabled = false } } }) end,
    ["zen"] = function() hl.config({ general = { gaps_in = 0, gaps_out = 0, border_size = 0 }, decoration = { blur = { enabled = false } } }) end,
    ["nz"] = function() hl.config({ general = { gaps_in = 5, gaps_out = 10, border_size = 3 }, decoration = { blur = { enabled = true } } }) end,
    ["nozen"] = function() hl.config({ general = { gaps_in = 5, gaps_out = 10, border_size = 3 }, decoration = { blur = { enabled = true } } }) end,

    ["wbrl"] = function() hl.dispatch(hl.dsp.exec_cmd("killall -SIGUSR2 waybar")) end,
    ["wpets"] = function() hl.dispatch(hl.dsp.exec_cmd("systemctl restart --user wpets.service wpets2.service")) end,

    ["ssa"] = function() screenshot("region") end,
    ["ss"] = function() screenshot("output --mode active") end,
    ["ssw"] = function() screenshot("window --mode active") end,

    ["mute"] = function()
        hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL + SHIFT + ENTER", key = "", window = "class:^discord$" }))
    end,
}

local function bufferexec(cmd)
    -- trim
    cmd = cmd:match("^%s*(.-)%s*$")

    -- handle :e filename, :! shellcmd etc
    if cmd:match("^!") then
        hl.exec_cmd(cmd:sub(2))
    elseif cmd:match("^e ") then
        hl.exec_cmd("xdg-open " .. cmd:sub(3))
    elseif cmd:match("^ws") then
        hl.dispatch(hl.dsp.focus({ workspace = cmd:sub(3) }))
    elseif cmd:match("^mv") then
        hl.dispatch(hl.dsp.window.move({ workspace = cmd:sub(3) }))
    elseif command_handlers[cmd] then
        command_handlers[cmd]()
    else
        hl.notification.create({
            text    = "E492: Not a command: " .. cmd,
            timeout = 3000,
            icon    = "error",
        })
    end
end

local HYPRVIM_STATE_SOCKET = "/tmp/hyprvim_state.socket"
local function write_waybar_state()
    local socket = io.open(HYPRVIM_STATE_SOCKET, "w")
    if not socket then return end

    if buf:len() == 0 and active then
        socket:write(string.format(
            '{"text":":▋"}', buf
        ))
    elseif buf:len() == 0 then
        socket:write(string.format(
            '{"text":""}', buf
        ))
    else
        socket:write(string.format(
            '{"text":":%s▋"}', buf
        ))
    end

    socket:close()
    hl.exec_cmd("pkill -RTMIN+9 waybar")
end

function Module.bufferopen()
    active = true
    buf = ""
    hl.dispatch(hl.dsp.submap("Command"))
    write_waybar_state()
end

-- register the submap
hl.define_submap("Command", function()
    hl.bind("BACKSPACE", function()
        buf = buf:sub(1, -2)
        write_waybar_state()
    end)

    hl.bind("RETURN", function()
        local cmd = buf
        buf = ""
        -- dismiss notification
        hl.dispatch(hl.dsp.submap("Normal"))
        bufferexec(cmd)
        active = false
        write_waybar_state()
    end)

    hl.bind("ESCAPE", function()
        buf = ""
        hl.dispatch(hl.dsp.submap("Normal"))
        active = false
        write_waybar_state()
    end)

    hl.bind("SUPER + C", function()
        buf = ""
        hl.dispatch(hl.dsp.submap("Normal"))
        active = false
        write_waybar_state()
    end)

    -- alpha + number keys feed the buffer
    for c in chars:gmatch(".") do
        local cap = c
        hl.bind(cap, function()
            buf = buf .. cap
            write_waybar_state()
        end)
    end

    hl.bind("SPACE", function()
        buf = buf .. " "
        write_waybar_state()
    end)

    hl.bind("SLASH", function()
        buf = buf .. "/"
        write_waybar_state()
    end)

    hl.bind("SHIFT + 1", function()
        buf = buf .. "!"
        write_waybar_state()
    end)
end)

return Module