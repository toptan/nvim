-- Leader keys, provider flags, Nerd Font flag and editor options.

-- Leader keys must be set before any mapping is defined.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable remote plugin providers; nothing in this config uses them.
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

-- No Nerd Font: later modules must use plain Unicode instead of icons.
vim.g.have_nerd_font = false

-- Indentation defaults. Buffer-local values from .editorconfig and
-- filetype plugins override these.
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = -1

-- Line numbers and scrolling.
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 8

-- Visual aids.
vim.opt.cursorline = true
vim.opt.colorcolumn = "81"
vim.opt.signcolumn = "yes"
vim.opt.list = true
vim.opt.listchars = {
  tab = "» ",
  trail = "·",
  nbsp = "␣",
  extends = "›",
  precedes = "‹",
}
