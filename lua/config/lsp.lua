-- Language-server activation and <leader>lf (gersemi for CMake).

-- Server (lsp/<name>.lua) per filetype.
local servers = {
  lua = "lua_ls",
  cmake = "neocmake",
  c = "clangd",
  cpp = "clangd",
  objc = "clangd",
  objcpp = "clangd",
  cuda = "clangd",
  sh = "bashls",
  bash = "bashls",
}
local enabled = {}

-- Enable each server on the first buffer of its filetype rather than at
-- startup: loading vim.lsp costs a few milliseconds. vim.lsp.enable() also
-- attaches the buffer whose FileType event triggered it.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("config_lsp", { clear = true, }),
  pattern = vim.tbl_keys(servers),
  callback = function(args)
    local name = servers[args.match]
    if enabled[name] then
      return
    end
    enabled[name] = true
    require("config.diagnostics").setup()
    vim.lsp.enable(name)
  end,
})

vim.keymap.set("n", "<leader>lf", function()
  if vim.bo.readonly or not vim.bo.modifiable then
    vim.notify("Buffer is read-only", vim.log.levels.WARN)
    return
  end
  -- CMake is formatted by gersemi only; neocmakelsp's formatter is disabled.
  if vim.bo.filetype == "cmake" then
    require("config.gersemi").format(0)
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
