-- Language-server activation and <leader>lf.

-- Enable lua_ls on the first Lua buffer rather than at startup: loading
-- vim.lsp costs a few milliseconds. vim.lsp.enable() also attaches the
-- buffer whose FileType event triggered it.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("config_lsp", { clear = true, }),
  pattern = "lua",
  once = true,
  callback = function()
    require("config.diagnostics").setup()
    vim.lsp.enable("lua_ls")
  end,
})

vim.keymap.set("n", "<leader>lf", function()
  if vim.bo.readonly or not vim.bo.modifiable then
    vim.notify("Buffer is read-only", vim.log.levels.WARN)
    return
  end
  local clients = vim.lsp.get_clients({
    bufnr = 0,
    method = "textDocument/formatting",
  })
  if #clients == 0 then
    vim.notify("No language server can format this buffer", vim.log.levels.WARN)
    return
  end
  -- Synchronous: edits typed meanwhile cannot race with the result, and the
  -- whole change is a single undo step.
  vim.lsp.buf.format({ bufnr = 0, async = false, timeout_ms = 3000, })
end, { desc = "Format buffer", })
