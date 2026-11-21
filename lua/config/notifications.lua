-- Notifications: vim.notify shown by mini.notify, with its defaults.
-- Plugin: core Neovim has no notification popup; this replaces a hand-written
-- one. If it cannot be installed or loaded, the built-in vim.notify stays.

local M = {}

local ok = pcall(vim.pack.add, {
  "https://github.com/nvim-mini/mini.notify",
}, { confirm = false, })
if ok then
  -- setup() also sets vim.notify to the plugin's implementation.
  ok = pcall(function()
    require("mini.notify").setup()
  end)
end
if not ok then
  -- One short line, so it never asks for Enter at startup. Scheduled so
  -- vim.pack's own progress message does not overwrite it.
  vim.schedule(function()
    vim.notify("mini.notify unavailable: notifications use the command line",
      vim.log.levels.WARN)
  end)
end

return M
