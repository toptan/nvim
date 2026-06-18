vim.pack.add({ "https://github.com/nvim-mini/mini.nvim" })

require("mini.misc").setup_termbg_sync()

-- Mini basics
require("mini.basics").setup({
  options = { basic = false },
  mappings = {
    -- Create `<C-hjkl>` mappings for window navigation
    windows = true,
    -- Create `<M-hjkl>` mappings for navigation in Insert and Command modes
    move_with_alt = true,
  },
})

-- Completion --
require("mini.completion").setup({
  lsp_completion = {
    source_func = "omnifunc",
    auto_setup = false, -- we set omnifunc manually in LspAttach
  },
})

-- Keystroke clues
local miniclue = require("mini.clue")
-- stylua: ignore
miniclue.setup({
  -- Define which clues to show. By default shows only clues for custom mappings
  -- (uses `desc` field from the mapping; takes precedence over custom clue).
  clues = {
    -- This is defined in 'plugin/20_keymaps.lua' with Leader group descriptions
    Config.leader_group_clues,
    miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.square_brackets(),
    miniclue.gen_clues.windows({ submode_resize = true }),
    miniclue.gen_clues.z(),
  },
  -- Explicitly opt-in for set of common keys to trigger clue window
  triggers = {
    { mode = { "n", "x" }, keys = "<Leader>" }, -- Leader triggers
    { mode = "n",          keys = "\\" },       -- mini.basics
    { mode = { "n", "x" }, keys = "[" },        -- mini.bracketed
    { mode = { "n", "x" }, keys = "]" },
    { mode = "i",          keys = "<C-x>" },    -- Built-in completion
    { mode = { "n", "x" }, keys = "g" },        -- `g` key
    { mode = { "n", "x" }, keys = "'" },        -- Marks
    { mode = { "n", "x" }, keys = "`" },
    { mode = { "n", "x" }, keys = '"' },        -- Registers
    { mode = { "i", "c" }, keys = "<C-r>" },
    { mode = "n",          keys = "<C-w>" },    -- Window commands
    { mode = { "n", "x" }, keys = "s" },        -- `s` key (mini.surround, etc.)
    { mode = { "n", "x" }, keys = "z" },        -- `z` key
  },
})

local function header_func()
  local hour = tonumber(vim.fn.strftime("%H"))
  -- [04:00, 12:00) - morning, [12:00, 20:00) - day, [20:00, 04:00) - evening
  local part_id = math.floor((hour + 4) / 8) + 1
  local day_part = ({ "evening", "morning", "afternoon", "evening" })[part_id]
  local username = vim.uv.os_get_passwd()["username"] or "USERNAME"

  return ("Good %s, %s!\n\nWhere there is a shell, there is a way."):format(
    day_part,
    username
  )
end

local function footer_func()
  return "The computer scientist's main challenge is not to\n"
    .. "get confused by the complexities of his own making.\n"
    .. "\n"
    .. "                              -- Edsger W. Dijkstra"
end

require("mini.starter").setup({
  header = header_func,
  footer = footer_func,
  query_updaters = "abcdefghijklmnopqrstuvwxyz0123456789_-",
})
