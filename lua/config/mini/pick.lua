local find_config_files = function()
  MiniPick.builtin.files(nil, { source = { cwd = "~/.config/nvim" } })
end

local find_git_files = function()
  MiniPick.builtin.files({ tool = "git" })
end

require("mini.pick").setup()

-- vim.ui.select = MiniPick.ui_select
vim.keymap.set("n", "<leader><leader>", MiniPick.builtin.buffers, { desc = "List buffers" })
vim.keymap.set("n", "<leader>ff", MiniPick.builtin.files, { desc = "[F]iles" })
vim.keymap.set("n", "<leader>fg", find_git_files, { desc = "[G]it files" })
vim.keymap.set("n", "<leader>fc", find_config_files, { desc = "Neovim [C]onfig files" })
vim.keymap.set("n", "<leader>sh", MiniPick.builtin.help, { desc = "[H]elp" })
vim.keymap.set("n", "<leader>ft", MiniPick.builtin.grep_live, { desc = "[T]ext in files" })
