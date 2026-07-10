-- mini.nvim module configuration lives here. Each module gets its own
-- `require("mini.<module>").setup({...})` block below.
local add = vim.pack.add

add({ "https://github.com/echasnovski/mini.nvim" })

-- See also:
-- - `:h mini.completion`
require("mini.completion").setup({
  lsp_completion = {
    -- Insert plain text on confirm; never expand LSP snippets.
    snippet_insert = function() end,
  },
  mappings = {
    -- Explicit: matches the default, but this is our "force completion" key.
    force_twostep = "<C-Space>",
  },
})

local imap = function(lhs, rhs)
  vim.keymap.set("i", lhs, rhs, { expr = true })
end

imap("<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end)
imap("<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end)
imap("<CR>", function()
  if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1 then
    return "<C-y>"
  end
  return "<CR>"
end)

-- mini.completion never preselects a candidate (completeopt=menuone,noselect), except we want
-- the sole match to be preselected so <CR> can confirm it immediately.
Config.new_autocmd("CompleteChanged", nil, function()
  local info = vim.fn.complete_info({ "items", "selected" })
  if info.selected == -1 and #info.items == 1 then
    vim.api.nvim_feedkeys(vim.keycode("<C-n>"), "n", false)
  end
end, "Preselect sole completion match")
