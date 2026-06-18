require("modules/monitor")
require("modules/env")
require("modules/programs")
require("modules/autostart")
require("modules/general")
require("modules/decoration")
require("modules/animations")
require("modules/misc")
require("modules/input")
require("modules/devices")
require("modules/binds")
require("lua/plugins/hyprvim").setup({
  keymaps = {
    NORMAL = {
      { "j", function() end },
      { "k", function() end },
      { "l", function() end },
      { "t", require("vim").motion.action("j"), { desc = "Down",         repeating = true } },
      { "n", require("vim").motion.action("k"), { desc = "Up",           repeating = true } },
      { "s", require("vim").motion.action("l"), { desc = "Right",        repeating = true } },
      { "SHIFT + j", function() end },
      { "SHIFT + k", function() end },
      { "SHIFT + l", function() end },
      { "SHIFT + t", require("vim").motion.action("0"), { desc = "Start of line"               } },
      { "SHIFT + n", function() end },
      { "SHIFT + s", require("vim").motion.action("$"), { desc = "End of line"                 } },
      { "CTRL + j",  function() end },
      { "CTRL + k",  function() end },
      { "CTRL + l",  function() end },
      { "CTRL + t",  require("vim").motion.action_seq({ { "CTRL", "DOWN" } }),  { desc = "Ctrl down",  repeating = true } },
      { "CTRL + n",  require("vim").motion.action_seq({ { "CTRL", "UP" } }),    { desc = "Ctrl up",    repeating = true } },
      { "CTRL + s",  require("vim").motion.action_seq({ { "CTRL", "RIGHT" } }), { desc = "Ctrl right", repeating = true } },
      { "ALT + j",   function() end },
      { "ALT + k",   function() end },
      { "ALT + l",   function() end },
      { "ALT + t",   function() require("hypr").send("ALT", "DOWN") end,  { desc = "Alt down"  } },
      { "ALT + n",   function() require("hypr").send("ALT", "UP") end,    { desc = "Alt up"    } },
      { "ALT + s",   function() require("hypr").send("ALT", "RIGHT") end, { desc = "Alt right" } },
    },
    VISUAL = {
      { "j", function() end },
      { "k", function() end },
      { "l", function() end },
      { "t", require("vim").motion.action_visual("j"), { desc = "Down",       repeating = true } },
      { "n", require("vim").motion.action_visual("k"), { desc = "Up",         repeating = true } },
      { "s", require("vim").motion.action_visual("l"), { desc = "Right",      repeating = true } },
      { "SHIFT + j", function() end },
      { "SHIFT + k", function() end },
      { "SHIFT + l", function() end },
      { "SHIFT + t", require("vim").motion.action_visual("J"), { desc = "Join"       } },
      { "SHIFT + n", function() end },
      { "SHIFT + s", require("vim").motion.action_visual("L"), { desc = "End of line" } },
    },
  },
})
require("modules/mode_indicator")
require("modules/windowrules")
require("modules/scrolling")
