-- Next-key clues by mini.clue: after a trigger key and a short pause, a
-- window lists the keys that may follow and what they do. Triggers and clues
-- follow the plugin's config quick start, plus two <Leader> group names.
-- Loaded at startup: the triggers must exist before the first key press.
-- Plugin: core Neovim cannot show which keys may follow a partially typed
-- key sequence; it only waits for 'timeoutlen'.

local M = {}

local ok = pcall(vim.pack.add, {
  "https://github.com/nvim-mini/mini.clue",
}, { confirm = false, })
if ok then
  ok = pcall(function()
    local miniclue = require("mini.clue")
    miniclue.setup({
      triggers = {
        -- Leader triggers
        { mode = { "n", "x", }, keys = "<Leader>", },

        -- `[` and `]` keys
        { mode = "n", keys = "[", },
        { mode = "n", keys = "]", },

        -- Built-in completion
        { mode = "i", keys = "<C-x>", },

        -- `g` key
        { mode = { "n", "x", }, keys = "g", },

        -- Marks
        { mode = { "n", "x", }, keys = "'", },
        { mode = { "n", "x", }, keys = "`", },

        -- Registers
        { mode = { "n", "x", }, keys = "\"", },
        { mode = { "i", "c", }, keys = "<C-r>", },

        -- Window commands
        { mode = "n", keys = "<C-w>", },

        -- `z` key
        { mode = { "n", "x", }, keys = "z", },
      },

      clues = {
        -- `<Leader>` groups ("+" marks a group, as in the built-in clues)
        { mode = { "n", "x", }, keys = "<Leader>l", desc = "+Language", },
        { mode = { "n", "x", }, keys = "<Leader>t", desc = "+Toggle", },

        miniclue.gen_clues.square_brackets(),
        miniclue.gen_clues.builtin_completion(),
        miniclue.gen_clues.g(),
        miniclue.gen_clues.marks(),
        miniclue.gen_clues.registers(),
        miniclue.gen_clues.windows(),
        miniclue.gen_clues.z(),
      },
    })
  end)
end
if not ok then
  -- One short line, so it never asks for Enter at startup. Scheduled so
  -- vim.pack's own progress message does not overwrite it.
  vim.schedule(function()
    vim.notify("mini.clue unavailable: no key clues", vim.log.levels.WARN)
  end)
end

return M
