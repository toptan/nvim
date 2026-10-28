-- Define a global table to share data between scripts if needed.
_G.Config = {}

-- Globals should be set in init.lua only.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- We want fancy icons.
vim.g.have_nerd_font = true

-- Disable unused providers.
-- Not really needed, just to avoid warnings in checkhealh report.
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0

-- Set up clipboard early on
vim.schedule(function() vim.opt.clipboard = "unnamedplus" end)
