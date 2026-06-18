vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 5
vim.opt.showmode = false
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 500
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.cursorline = true
vim.opt.colorcolumn = "80"
vim.opt.scrolloff = 10
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.foldlevel = 99

vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

vim.cmd.colorscheme("retrobox")
