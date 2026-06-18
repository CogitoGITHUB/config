local path = "/run/current-system/profile/share/hyprvim/init.lua"
local chunk, err = loadfile(path)
if not chunk then
  error(err)
end
return chunk()
