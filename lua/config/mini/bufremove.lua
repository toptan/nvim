require("mini.bufremove").setup()

vim.keymap.set("n", "<leader>x", MiniBufremove.delete, { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>bd", MiniBufremove.delete, { desc = "[D]elete" })
