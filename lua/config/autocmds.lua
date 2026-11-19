-- Small general autocommands.

-- Briefly highlight yanked text; deletes and changes are ignored.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("config_yank_highlight", {
    clear = true,
  }),
  callback = function()
    vim.hl.on_yank()
  end,
})
