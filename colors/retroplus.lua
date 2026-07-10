-- retroplus: retrobox with the modern highlight groups it lacks (Tree-sitter @*,
-- LSP/diagnostics, semantic tokens, floating windows, mini.nvim) added using
-- catppuccin's color-assignment logic, backed by a gruvbox palette. More
-- colorful than `retro`. See lua/retro/init.lua. Pure Lua.
require("retro").load({ name = "retroplus", base = "retrobox", flavor = "plus" })
