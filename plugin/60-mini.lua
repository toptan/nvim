-- mini.nvim module configuration lives here. Each module gets its own
-- `require("mini.<module>").setup({...})` block below.
local add = vim.pack.add

add({ "https://github.com/nvim-mini/mini.nvim" })

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

-- See also:
-- - `:h mini.pairs`
require("mini.pairs").setup()

-- See also:
-- - `:h mini.bracketed`
require("mini.bracketed").setup()

-- See also:
-- - `:h mini.ai`
local function treesitter_textobject(captures)
  -- `gen_spec.treesitter()` errors (rather than reporting "no match") when the buffer's
  -- language has no parser or no `textobjects.scm` query defining the requested captures.
  -- Swallow that so `af`/`if`/`ac`/`ic` degrade to "nothing found" on unsupported filetypes.
  local spec = require("mini.ai").gen_spec.treesitter(captures)
  return function(...)
    local ok, res = pcall(spec, ...)
    if not ok then
      return {}
    end
    return res
  end
end

require("mini.ai").setup({
  custom_textobjects = {
    f = treesitter_textobject({ a = "@function.outer", i = "@function.inner" }),
    c = treesitter_textobject({ a = "@class.outer", i = "@class.inner" }),
  },
})

-- See also:
-- - `:h mini.surround`
require("mini.surround").setup()

-- See also:
-- - `:h mini.bufremove`
require("mini.bufremove").setup()

vim.keymap.set("n", "<Leader>bd", function()
  require("mini.bufremove").delete(0, false)
end, { desc = "Delete buffer" })

vim.keymap.set("n", "<Leader>bD", function()
  require("mini.bufremove").delete(0, true)
end, { desc = "Force delete buffer" })

-- See also:
-- - `:h mini.notify`
require("mini.notify").setup()
vim.notify = require("mini.notify").make_notify()

vim.keymap.set("n", "<Leader>on", require("mini.notify").show_history, { desc = "Notification history" })

-- See also:
-- - `:h mini.trailspace`
require("mini.trailspace").setup()

vim.keymap.set("n", "<Leader>cw", function()
  require("mini.trailspace").trim()
end, { desc = "Trim trailing whitespace" })

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
  -- Falls back to mini.pairs' smart Enter (splits an empty pair across lines), which itself
  -- falls back to a plain <CR> when the cursor isn't inside a pair.
  return require("mini.pairs").cr()
end)
imap("<Esc>", function()
  return vim.fn.pumvisible() == 1 and "<C-e><Esc>" or "<Esc>"
end)

-- mini.completion never preselects a candidate (completeopt=menuone,noselect), except we want
-- the sole match to be preselected so <CR> can confirm it immediately.
Config.new_autocmd("CompleteChanged", nil, function()
  local info = vim.fn.complete_info({ "items", "selected" })
  if info.selected == -1 and #info.items == 1 then
    vim.api.nvim_feedkeys(vim.keycode("<C-n>"), "n", false)
  end
end, "Preselect sole completion match")

-- See also:
-- - `:h mini.clue`
local miniclue = require("mini.clue")
miniclue.setup({
  triggers = {
    { mode = "n", keys = "<Leader>" },
    { mode = "x", keys = "<Leader>" },

    { mode = "n", keys = "g" },
    { mode = "x", keys = "g" },

    { mode = "n", keys = "z" },
    { mode = "x", keys = "z" },

    { mode = "n", keys = "'" },
    { mode = "n", keys = "`" },
    { mode = "x", keys = "'" },
    { mode = "x", keys = "`" },

    { mode = "n", keys = '"' },
    { mode = "x", keys = '"' },
    { mode = "i", keys = "<C-r>" },
    { mode = "c", keys = "<C-r>" },

    { mode = "n", keys = "<C-w>" },

    { mode = "n", keys = "[" },
    { mode = "x", keys = "[" },
    { mode = "n", keys = "]" },
    { mode = "x", keys = "]" },
  },

  clues = {
    Config.leader_group_clues,
    miniclue.gen_clues.g(),
    miniclue.gen_clues.z(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.builtin_completion(),
  },
})
