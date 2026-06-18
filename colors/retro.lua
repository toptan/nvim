-- retro: retrobox with the modern highlight groups it lacks (Tree-sitter @*,
-- LSP/diagnostics, semantic tokens, floating windows, mini.nvim) added, keeping
-- retrobox's original hues by linking captures to its classic base groups.
-- See lua/retro/init.lua. Pure Lua.
require("retro").load({ name = "retro", base = "retrobox", flavor = "classic" })
