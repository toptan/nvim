require("mini.files").setup()

vim.keymap.set("n", "<leader>fe", MiniFiles.open, { desc = "Via [E]xplorer" })
vim.keymap.set("n", "-", function()
  MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
end, { desc = "Current buffer directory" })
