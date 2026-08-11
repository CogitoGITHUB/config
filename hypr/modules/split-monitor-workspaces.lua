package.path = package.path .. ";" .. os.getenv("HOME")
	.. "/.config/hypr/plugins/plugins-src/split-monitor-workspaces/lua/?.lua"

local smw = require("split-monitor-workspaces")

smw.setup({
	workspace_count = 10,
	monitor_priority = { "eDP-1" },
	keep_focused = true,
	enable_notifications = true,
	enable_persistent_workspaces = true,
	enable_wrapping = true,
	link_monitors = false,
})

local mainMod = "SUPER"
for i = 1, 9 do
	local n = tostring(i)
	hl.bind(mainMod .. " + " .. n, smw.workspace(n))
	hl.bind(mainMod .. " + SHIFT + " .. n, smw.move_to_workspace_silent(n))
end
hl.bind(mainMod .. " + 0", smw.workspace("10"))
hl.bind(mainMod .. " + SHIFT + 0", smw.move_to_workspace_silent("10"))
hl.bind(mainMod .. " + mouse_down", smw.cycle_workspaces("next"))
hl.bind(mainMod .. " + mouse_up", smw.cycle_workspaces("prev"))