-- defaultplus: Neovim's built-in "default" colorscheme with the modern
-- highlight groups it lacks added using catppuccin's color-assignment logic,
-- backed by the Nvim default palette. See lua/retro/init.lua. Pure Lua.
require("retro").load({ name = "defaultplus", base = "default", flavor = "plus" })
