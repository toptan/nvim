-- ┌─────────────────┐
-- │ Custom mappings │
-- └─────────────────┘
--
-- This file contains definitions of custom general and Leader mappings.

-- General mappings ===========================================================

-- Use this section to add custom general mappings. See `:h vim.keymap.set()`.

-- An example helper to create a Normal mode mapping
local nmap = function(lhs, rhs, desc)
  -- See `:h vim.keymap.set()`
  vim.keymap.set("n", lhs, rhs, { desc = desc, })
end

-- Paste linewise before/after current line
-- Usage: `yiw` to yank a word and `]p` to put it on the next line.
-- nmap('[p', '<Cmd>exe "iput! " . v:register<CR>', 'Paste Above')
-- nmap(']p', '<Cmd>exe "iput "  . v:register<CR>', 'Paste Below')

-- Create a global table with information about Leader groups in certain modes.
-- This is used to provide 'mini.clue' with extra clues.
-- Add an entry if you create a new group.
Config.leader_group_clues = {
  { mode = "n", keys = "<Leader>b", desc = "+Buffer", },
  { mode = "n", keys = "<Leader>e", desc = "+Explore/Edit", },
  { mode = "n", keys = "<Leader>f", desc = "+Find", },
  { mode = "n", keys = "<Leader>g", desc = "+Git", },
  { mode = "n", keys = "<Leader>l", desc = "+Language", },
  { mode = "n", keys = "<Leader>m", desc = "+Map", },
  { mode = "n", keys = "<Leader>o", desc = "+Other", },
  { mode = "n", keys = "<Leader>s", desc = "+Session", },
  { mode = "n", keys = "<Leader>t", desc = "+Terminal", },
  { mode = "n", keys = "<Leader>v", desc = "+Visits", },

  { mode = "x", keys = "<Leader>g", desc = "+Git", },
  { mode = "x", keys = "<Leader>l", desc = "+Language", },
}

-- Helpers for a more concise `<Leader>` mappings.
-- Most of the mappings use `<Cmd>...<CR>` string as a right hand side (RHS) in
-- an attempt to be more concise yet descriptive. See `:h <Cmd>`.
-- This approach also doesn't require the underlying commands/functions to exist
-- during mapping creation: a "lazy loading" approach to improve startup time.
local nmap_leader = function(suffix, rhs, desc)
  vim.keymap.set("n", "<Leader>" .. suffix, rhs, { desc = desc, })
end
local xmap_leader = function(suffix, rhs, desc)
  vim.keymap.set("x", "<Leader>" .. suffix, rhs, { desc = desc, })
end

vim.keymap.set("n", "<Tab>", "<Cmd>bnext<CR>", { desc = "Next Buffer", })

-- b is for 'Buffer'. Common usage:
-- - `<Leader>bs` - create scratch (temporary) buffer
-- - `<Leader>ba` - navigate to the alternative buffer
-- - `<Leader>bw` - wipeout (fully delete) current buffer
local new_scratch_buffer = function()
  vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true))
end

nmap_leader("ba", "<Cmd>b#<CR>", "Alternate")
nmap_leader("bd", "<Cmd>lua MiniBufremove.delete()<CR>", "Delete")
nmap_leader("bD", "<Cmd>lua MiniBufremove.delete(0, true)<CR>", "Delete!")
nmap_leader("bs", new_scratch_buffer, "Scratch")
nmap_leader("bw", "<Cmd>lua MiniBufremove.wipeout()<CR>", "Wipeout")
nmap_leader("bW", "<Cmd>lua MiniBufremove.wipeout(0, true)<CR>", "Wipeout!")

-- e is for 'Explore' and 'Edit'. Common usage:
-- - `<Leader>ed` - open explorer at current working directory
-- - `<Leader>ef` - open directory of current file (needs to be present on disk)
-- - `<Leader>ei` - edit 'init.lua'
-- - All mappings that use `edit_plugin_file` - edit 'plugin/' config files
local edit_plugin_file = function(filename)
  return string.format("<Cmd>edit %s/plugin/%s<CR>", vim.fn.stdpath("config"),
                       filename)
end

local explore_at_file =
"<Cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>"

local explore_quickfix = function()
  vim.cmd(vim.fn.getqflist({ winid = true, }).winid ~= 0 and "cclose" or
    "copen")
end

local explore_locations = function()
  vim.cmd(vim.fn.getloclist(0, { winid = true, }).winid ~= 0 and "lclose" or
    "lopen")
end

nmap_leader("ed", "<Cmd>lua MiniFiles.open()<CR>", "Directory")
nmap_leader("ef", explore_at_file, "File directory")
nmap_leader("ei", "<Cmd>edit $MYVIMRC<CR>", "init.lua")
nmap_leader("ek", edit_plugin_file("20_keymaps.lua"), "Keymaps config")
nmap_leader("em", edit_plugin_file("30_mini.lua"), "MINI config")
nmap_leader("en", "<Cmd>lua MiniNotify.show_history()<CR>", "Notifications")
nmap_leader("eo", edit_plugin_file("10_options.lua"), "Options config")
nmap_leader("ep", edit_plugin_file("40_plugins.lua"), "Plugins config")
nmap_leader("eq", explore_quickfix, "Quickfix list")
nmap_leader("eQ", explore_locations, "Location list")

-- f is for 'Fuzzy Find'. Common usage:
-- - `<Leader>ff` - find files; for best performance requires `ripgrep`
-- - `<Leader>fg` - find inside files; requires `ripgrep`
-- - `<Leader>fh` - find help tag
-- - `<Leader>fr` - resume latest picker
-- - `<Leader>fv` - all visited paths; requires 'mini.visits'
--
-- All these use 'mini.pick'. See `:h MiniPick-overview` for an overview.
local pick_added_hunks_buf = '<Cmd>Pick git_hunks path="%" scope="staged"<CR>'
local pick_workspace_symbols_live =
'<Cmd>Pick lsp scope="workspace_symbol_live"<CR>'

nmap_leader("f/", '<Cmd>Pick history scope="/"<CR>', '"/" history')
nmap_leader("f:", '<Cmd>Pick history scope=":"<CR>', '":" history')
nmap_leader("fa", '<Cmd>Pick git_hunks scope="staged"<CR>', "Added hunks (all)")
nmap_leader("fA", pick_added_hunks_buf, "Added hunks (buf)")
nmap_leader("fb", "<Cmd>Pick buffers<CR>", "Buffers")
nmap_leader("fc", "<Cmd>Pick git_commits<CR>", "Commits (all)")
nmap_leader("fC", '<Cmd>Pick git_commits path="%"<CR>', "Commits (buf)")
nmap_leader("fd", '<Cmd>Pick diagnostic scope="all"<CR>', "Diagnostic workspace")
nmap_leader("fD", '<Cmd>Pick diagnostic scope="current"<CR>', "Diagnostic buffer")
nmap_leader("ff", "<Cmd>Pick files<CR>", "Files")
nmap_leader("fg", "<Cmd>Pick grep_live<CR>", "Grep live")
nmap_leader("fG", '<Cmd>Pick grep pattern="<cword>"<CR>', "Grep current word")
nmap_leader("fh", "<Cmd>Pick help<CR>", "Help tags")
nmap_leader("fH", "<Cmd>Pick hl_groups<CR>", "Highlight groups")
nmap_leader("fl", '<Cmd>Pick buf_lines scope="all"<CR>', "Lines (all)")
nmap_leader("fL", '<Cmd>Pick buf_lines scope="current"<CR>', "Lines (buf)")
nmap_leader("fm", "<Cmd>Pick git_hunks<CR>", "Modified hunks (all)")
nmap_leader("fM", '<Cmd>Pick git_hunks path="%"<CR>', "Modified hunks (buf)")
nmap_leader("fr", "<Cmd>Pick resume<CR>", "Resume")
nmap_leader("fR", '<Cmd>Pick lsp scope="references"<CR>', "References (LSP)")
nmap_leader("fs", pick_workspace_symbols_live, "Symbols workspace (live)")
nmap_leader("fS", '<Cmd>Pick lsp scope="document_symbol"<CR>', "Symbols document")
nmap_leader("fv", '<Cmd>Pick visit_paths cwd=""<CR>', "Visit paths (all)")
nmap_leader("fV", "<Cmd>Pick visit_paths<CR>", "Visit paths (cwd)")

-- l is for 'Language'. Common usage:
-- - `<Leader>ld` - show more diagnostic details in a floating window
-- - `<Leader>lr` - perform rename via LSP
-- - `<Leader>ls` - navigate to source definition of symbol under cursor
--
-- NOTE: most LSP mappings represent a more structured way of replacing built-in
-- LSP mappings (like `:h gra` and others). This is needed because `gr` is mapped
-- by an "replace" operator in 'mini.operators' (which is more commonly used).
nmap_leader("la", "<Cmd>lua vim.lsp.buf.code_action()<CR>", "Actions")
nmap_leader("ld", "<Cmd>lua vim.diagnostic.open_float()<CR>", "Diagnostic popup")
nmap_leader("lf", "<Cmd>lua vim.lsp.buf.format()<CR>", "Format")
nmap_leader("li", "<Cmd>lua vim.lsp.buf.implementation()<CR>", "Implementation")
nmap_leader("lh", "<Cmd>lua vim.lsp.buf.hover()<CR>", "Hover")
nmap_leader("ll", "<Cmd>lua vim.lsp.codelens.run()<CR>", "Lens")
nmap_leader("lr", "<Cmd>lua vim.lsp.buf.rename()<CR>", "Rename")
nmap_leader("lR", "<Cmd>lua vim.lsp.buf.references()<CR>", "References")
nmap_leader("ls", "<Cmd>lua vim.lsp.buf.definition()<CR>", "Source definition")
nmap_leader("lt", "<Cmd>lua vim.lsp.buf.type_definition()<CR>", "Type definition")

xmap_leader("lf", "<Cmd>lua vim.lsp.buf.format()<CR>", "Format selection")
