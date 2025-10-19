local function init()
  local clue = require("mini.clue")
  local opts = {
    window = {
      config = { width = "auto" },
    },
    triggers = {
      -- Leader triggers
      { mode = "n", keys = "<Leader>" },
      { mode = "x", keys = "<Leader>" },

      -- Built-in completion
      { mode = "i", keys = "<C-x>" },

      -- `g` key
      { mode = "n", keys = "g" },
      { mode = "x", keys = "g" },

      -- Marks
      { mode = "n", keys = "'" },
      { mode = "n", keys = "`" },
      { mode = "x", keys = "'" },
      { mode = "x", keys = "`" },

      -- Registers
      { mode = "n", keys = '"' },
      { mode = "x", keys = '"' },
      { mode = "i", keys = "<C-r>" },
      { mode = "c", keys = "<C-r>" },

      -- Window commands
      { mode = "n", keys = "<C-w>" },

      -- `z` key
      { mode = "n", keys = "z" },
      { mode = "x", keys = "z" },
    },

    clues = {
      -- Enhance this by adding descriptions for <Leader> mapping groups
      clue.gen_clues.builtin_completion(),
      clue.gen_clues.g(),
      clue.gen_clues.marks(),
      clue.gen_clues.registers(),
      clue.gen_clues.windows(),
      clue.gen_clues.z(),

      { mode = "n", keys = "<Leader>b", desc = "+[B]uffers" },
      { mode = "n", keys = "<Leader>c", desc = "+[C]ode" },
      { mode = "n", keys = "<Leader>f", desc = "+[F]ind" },
      { mode = "n", keys = "<Leader>s", desc = "+[S]earch" },
      { mode = "n", keys = "<Leader>t", desc = "+[T]oggle" },
      { mode = "n", keys = "<Leader>m", desc = "+[M]isc" },
    },
  }
  clue.setup(opts)
end

init()
