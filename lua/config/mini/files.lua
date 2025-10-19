require("mini.files").setup()

vim.keymap.set("n", "<leader>fe", MiniFiles.open, { desc = "Via [E]xplorer" })
