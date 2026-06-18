hl.on("keybinds.submap", function(name)
  hl.notification.create({
    text    = name,
    timeout = 1500,
    icon    = "info",
  })
end)
