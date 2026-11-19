-- Diagnostic display (virtual text / virtual lines) and the three toggles.

local M = {}

local did_setup = false

-- Apply the initial display once. Deferred until it is needed so that
-- vim.diagnostic is not loaded at startup.
function M.setup()
  if did_setup then
    return
  end
  did_setup = true
  vim.diagnostic.config({ virtual_text = true, virtual_lines = false, })
end

-- Diagnostics from any source, not only lua_ls, get the initial display.
-- Creating the autocommand does not load vim.diagnostic.
vim.api.nvim_create_autocmd("DiagnosticChanged", {
  group = vim.api.nvim_create_augroup("config_diagnostics", { clear = true, }),
  once = true,
  callback = function()
    M.setup()
  end,
})

local function notify(msg)
  vim.notify(msg, vim.log.levels.INFO)
end

local function state(on)
  return on and "on" or "off"
end

vim.keymap.set("n", "<leader>td", function()
  M.setup()
  local enabled = not vim.diagnostic.is_enabled()
  vim.diagnostic.enable(enabled)
  notify("Diagnostics: " .. state(enabled))
end, { desc = "Toggle diagnostics", })

-- Flip one display setting. While diagnostics are disabled the change is
-- kept and applies when they are turned back on.
local function toggle(key, label)
  M.setup()
  local on = not vim.diagnostic.config()[key]
  vim.diagnostic.config({ [key] = on, })
  local msg = ("Diagnostic %s: %s"):format(label, state(on))
  if not vim.diagnostic.is_enabled() then
    msg = msg .. " (diagnostics are off)"
  end
  notify(msg)
end

vim.keymap.set("n", "<leader>tt", function()
  toggle("virtual_text", "virtual text")
end, { desc = "Toggle diagnostic virtual text", })
vim.keymap.set("n", "<leader>tl", function()
  toggle("virtual_lines", "virtual lines")
end, { desc = "Toggle diagnostic virtual lines", })

return M
