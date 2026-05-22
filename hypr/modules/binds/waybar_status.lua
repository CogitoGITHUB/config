local HYPRVIM_SUBMAP_SOCKET = "/tmp/hyprvim_submap.socket"

hl.on("keybinds.submap", function(name)
    local submap_icons = {
        ["Normal"]    = { icon = "󰇀 ", class = "Normal" },
        ["Insert"]    = { icon = "󱂬 ", class = "Insert" },
        ["Visual"]    = { icon = "󰙀 ", class = "Visual" },
        ["resize"]    = { icon = "󰩨 ", class = "Resize" },
        ["move"]      = { icon = "󰆰 ", class = "Move" },
        ["workspace"] = { icon = " ", class = "Workspace" },
        ["Game"]      = { icon = "󰊖 ", class = "Game" },
        ["Command"]   = { icon = " ", class = "Command" },
    }

    local state = submap_icons[name] or { icon = "?" .. name, class = "unknown" }

    -- Write JSON for waybar to read
    local socket = io.open(HYPRVIM_SUBMAP_SOCKET, "w")
    if socket then
        socket:write(string.format(
            '{"text":"%s","class":"%s","tooltip":"%s"}\n',
            state.icon .. name, state.class, name .. " Mode"
        ))
        socket:close()
    end

    hl.exec_cmd("pkill -RTMIN+8 waybar")
end)