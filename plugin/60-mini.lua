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

-- See also:
-- - `:h mini.input`
require("mini.input").setup()

-- See also:
-- - `:h mini.cursorword`
require("mini.cursorword").setup()

-- See also:
-- - `:h mini.files`
require("mini.files").setup()

local function toggle_files(path)
  if not require("mini.files").close() then
    require("mini.files").open(path)
  end
end

vim.keymap.set("n", "-", function()
  toggle_files(vim.api.nvim_buf_get_name(0))
end, { desc = "Toggle file explorer (current file)" })

vim.keymap.set("n", "<Leader>ed", function()
  toggle_files(vim.fn.getcwd())
end, { desc = "Explore directory (cwd)" })

vim.keymap.set("n", "<Leader>ec", function()
  toggle_files(vim.fn.stdpath("config"))
end, { desc = "Explore Neovim config directory" })

-- See also:
-- - `:h mini.indentscope`
require("mini.indentscope").setup({
  draw = {
    animation = require("mini.indentscope").gen_animation.none(),
  },
})

-- See also:
-- - `:h mini.statusline`
local function diagnostics_by_severity(trunc_width)
  local ministatusline = require("mini.statusline")
  if ministatusline.is_truncated(trunc_width) or not vim.diagnostic.is_enabled({ bufnr = 0 }) then
    return {}
  end

  local count = vim.diagnostic.count(0)
  local levels = {
    { name = "ERROR", sign = "E", hl = "DiagnosticError" },
    { name = "WARN", sign = "W", hl = "DiagnosticWarn" },
    { name = "INFO", sign = "I", hl = "DiagnosticInfo" },
    { name = "HINT", sign = "H", hl = "DiagnosticHint" },
  }

  local groups = {}
  for _, level in ipairs(levels) do
    local n = count[vim.diagnostic.severity[level.name]] or 0
    if n > 0 then
      table.insert(groups, { hl = level.hl, strings = { level.sign .. n } })
    end
  end
  return groups
end

require("mini.statusline").setup({
  content = {
    active = function()
      local ministatusline = require("mini.statusline")
      local mode, mode_hl = ministatusline.section_mode({ trunc_width = 120 })
      local git = ministatusline.section_git({ trunc_width = 40 })
      local diff = ministatusline.section_diff({ trunc_width = 75 })
      local lsp = ministatusline.section_lsp({ trunc_width = 75 })
      local filename = ministatusline.section_filename({ trunc_width = 140 })
      local fileinfo = ministatusline.section_fileinfo({ trunc_width = 120 })
      local location = ministatusline.section_location({ trunc_width = 75 })
      local search = ministatusline.section_searchcount({ trunc_width = 75 })

      local groups = {
        { hl = mode_hl, strings = { mode } },
        { hl = "MiniStatuslineDevinfo", strings = { git, diff } },
      }
      vim.list_extend(groups, diagnostics_by_severity(75))
      table.insert(groups, { hl = "MiniStatuslineDevinfo", strings = { lsp } })
      table.insert(groups, "%<")
      table.insert(groups, { hl = "MiniStatuslineFilename", strings = { filename } })
      table.insert(groups, "%=")
      table.insert(groups, { hl = "MiniStatuslineFileinfo", strings = { fileinfo } })
      table.insert(groups, { hl = mode_hl, strings = { search, location } })

      return ministatusline.combine_groups(groups)
    end,
  },
})

-- See also:
-- - `:h mini.pick`
require("mini.pick").setup()

vim.keymap.set("n", "<Leader>ff", function()
  require("mini.pick").builtin.files()
end, { desc = "Find files" })

vim.keymap.set("n", "<Leader>fg", function()
  require("mini.pick").builtin.grep_live()
end, { desc = "Live grep" })

vim.keymap.set("n", "<Leader>fG", function()
  require("mini.pick").builtin.grep()
end, { desc = "Grep (pattern)" })

vim.keymap.set("n", "<Leader>fb", function()
  require("mini.pick").builtin.buffers()
end, { desc = "Find buffers" })

vim.keymap.set("n", "<Leader>fh", function()
  require("mini.pick").builtin.help()
end, { desc = "Find help tags" })

vim.keymap.set("n", "<Leader>fr", function()
  require("mini.pick").builtin.resume()
end, { desc = "Resume last picker" })

vim.keymap.set("n", "<Leader>fc", function()
  -- `builtin.cli()` takes `command` as an argv table, not an interactive prompt;
  -- prompt for one via `vim.ui.input()` (mini.input) and split it into argv ourselves.
  vim.ui.input({ prompt = "CLI command: " }, function(input)
    if input == nil or input == "" then
      return
    end
    require("mini.pick").builtin.cli({ command = vim.split(input, "%s+") })
  end)
end, { desc = "Pick from CLI output" })

-- See also:
-- - `:h mini.extra`
require("mini.extra").setup()

vim.keymap.set("n", "<Leader>fd", function()
  require("mini.extra").pickers.diagnostic()
end, { desc = "Diagnostics" })

vim.keymap.set("n", "<Leader>fe", function()
  require("mini.extra").pickers.explorer()
end, { desc = "File explorer (picker)" })

vim.keymap.set("n", "<Leader>fk", function()
  require("mini.extra").pickers.keymaps()
end, { desc = "Keymaps" })

vim.keymap.set("n", "<Leader>fl", function()
  require("mini.extra").pickers.buf_lines()
end, { desc = "Buffer lines" })

vim.keymap.set("n", "<Leader>fm", function()
  require("mini.extra").pickers.manpages()
end, { desc = "Manpages" })

vim.keymap.set("n", "<Leader>fM", function()
  require("mini.extra").pickers.marks()
end, { desc = "Marks" })

vim.keymap.set("n", "<Leader>fo", function()
  require("mini.extra").pickers.oldfiles()
end, { desc = "Old files" })

vim.keymap.set("n", "<Leader>fO", function()
  require("mini.extra").pickers.options()
end, { desc = "Options" })

vim.keymap.set("n", "<Leader>fR", function()
  require("mini.extra").pickers.registers()
end, { desc = "Registers" })

vim.keymap.set("n", "<Leader>fs", function()
  require("mini.extra").pickers.spellsuggest()
end, { desc = "Spelling suggestions" })

vim.keymap.set("n", "<Leader>fT", function()
  require("mini.extra").pickers.colorschemes()
end, { desc = "Colorschemes" })

vim.keymap.set("n", "<Leader>fx", function()
  require("mini.extra").pickers.hl_groups()
end, { desc = "Highlight groups" })

vim.keymap.set("n", "<Leader>fy", function()
  require("mini.extra").pickers.history()
end, { desc = "Command/search history" })

vim.keymap.set("n", "<Leader>fC", function()
  require("mini.extra").pickers.commands()
end, { desc = "Commands" })

vim.keymap.set("n", "<Leader>ft", function()
  require("mini.extra").pickers.treesitter()
end, { desc = "Treesitter nodes" })

vim.keymap.set("n", "<Leader>gb", function()
  require("mini.extra").pickers.git_branches()
end, { desc = "Git branches" })

vim.keymap.set("n", "<Leader>gc", function()
  require("mini.extra").pickers.git_commits()
end, { desc = "Git commits" })

vim.keymap.set("n", "<Leader>gf", function()
  require("mini.extra").pickers.git_files()
end, { desc = "Git files (tracked)" })

vim.keymap.set("n", "<Leader>gh", function()
  require("mini.extra").pickers.git_hunks()
end, { desc = "Git hunks (unstaged)" })

vim.keymap.set("n", "<Leader>ld", function()
  require("mini.extra").pickers.lsp({ scope = "declaration" })
end, { desc = "LSP declaration" })

vim.keymap.set("n", "<Leader>lD", function()
  require("mini.extra").pickers.lsp({ scope = "definition" })
end, { desc = "LSP definition" })

vim.keymap.set("n", "<Leader>lo", function()
  require("mini.extra").pickers.lsp({ scope = "document_symbol" })
end, { desc = "LSP document symbols (outline)" })

vim.keymap.set("n", "<Leader>li", function()
  require("mini.extra").pickers.lsp({ scope = "implementation" })
end, { desc = "LSP implementation" })

vim.keymap.set("n", "<Leader>lr", function()
  require("mini.extra").pickers.lsp({ scope = "references" })
end, { desc = "LSP references" })

vim.keymap.set("n", "<Leader>lt", function()
  require("mini.extra").pickers.lsp({ scope = "type_definition" })
end, { desc = "LSP type definition" })

vim.keymap.set("n", "<Leader>lw", function()
  require("mini.extra").pickers.lsp({ scope = "workspace_symbol" })
end, { desc = "LSP workspace symbols" })

vim.keymap.set("n", "<Leader>lW", function()
  require("mini.extra").pickers.lsp({ scope = "workspace_symbol_live" })
end, { desc = "LSP workspace symbols (live)" })

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
