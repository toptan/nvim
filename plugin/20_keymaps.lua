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
