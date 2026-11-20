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
-- Room for 5-digit line numbers plus the separating space.
vim.opt.numberwidth = 6

-- Search: confirm before jumping, smart case. The built-in command-line
-- count is hidden because config.search shows its own label.
vim.opt.incsearch = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.shortmess:append("S")

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

-- Insert-mode completion: a menu even for one match, nothing selected or
-- inserted until chosen, item details in a popup, fuzzy narrowing as you type.
vim.opt.completeopt = { "menuone", "noselect", "popup", "fuzzy", }

-- Floating windows: default border for every float that does not set its
-- own. Plain Unicode box drawing, no Nerd Font glyphs.
vim.opt.winborder = "rounded"
