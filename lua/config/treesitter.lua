-- Tree-sitter: parsers, highlighting, folding, indentation, text objects.
--
-- The plugins are registered at startup but loaded (:packadd) only when the
-- first buffer of a supported filetype appears. That buffer also installs
-- the missing parsers in the background; buffers whose parser was missing
-- switch to tree-sitter once it is ready. Plugin changes made by vim.pack
-- trigger one parser update.

local M = {}

-- Parsers to install: the single source of truth for this feature.
local LANGUAGES = {
  "asm",
  "bash",
  "c",
  "cmake",
  "cpp",
  "editorconfig",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "regex",
  "vim",
  "vimdoc",
}

-- Filetype -> parser. markdown_inline and regex are injection-only.
local FILETYPES = {
  asm = "asm",
  bash = "bash",
  sh = "bash",
  c = "c",
  cmake = "cmake",
  cpp = "cpp",
  editorconfig = "editorconfig",
  lua = "lua",
  markdown = "markdown",
  python = "python",
  vim = "vim",
  help = "vimdoc",
}

local PLUGINS = { "nvim-treesitter", "nvim-treesitter-textobjects", }

local FOLDEXPR = "v:lua.vim.treesitter.foldexpr()"
local INDENTEXPR = "v:lua.require'nvim-treesitter'.indentexpr()"

local state = {
  loaded = nil, -- nil: not tried yet; then true/false for the session
  install = "idle", -- "idle" | "running" | "done"
  update_pending = false,
  pending = {}, -- buffers waiting for their parser
  tools_warned = false,
}

local group = vim.api.nvim_create_augroup("config_treesitter", {
  clear = true,
})

-- Build tools nvim-treesitter needs; returns the missing ones.
local function missing_tools()
  local missing = {}
  for _, tool in ipairs({ "tree-sitter", "curl", "tar", }) do
    if vim.fn.executable(tool) == 0 then
      table.insert(missing, tool)
    end
  end
  local has_cc = false
  for _, cc in ipairs({ vim.env.CC or "", "cc", "gcc", "clang", }) do
    local exe = vim.split(cc, " ", { trimempty = true, })[1]
    if exe and vim.fn.executable(exe) == 1 then
      has_cc = true
      break
    end
  end
  if not has_cc then
    table.insert(missing, "C compiler")
  end
  return missing
end

-- The only message of this module: once per session (Principle IV).
local function warn_missing(tools)
  if state.tools_warned then
    return
  end
  state.tools_warned = true
  vim.notify(
    "Tree-sitter parsers not installed, missing: "
    .. table.concat(tools, ", "),
    vim.log.levels.WARN
  )
end

-- Runs a pending parser update; extra calls from one batch do nothing.
local function run_update()
  if not state.update_pending then
    return
  end
  state.update_pending = false
  local missing = missing_tools()
  if #missing > 0 then
    warn_missing(missing)
    return
  end
  pcall(function()
    require("nvim-treesitter").update(LANGUAGES)
  end)
end

-- Must exist before vim.pack.add() so that it also sees the first install.
-- It never loads the plugins itself: the update waits for the first
-- supported buffer when they are not loaded yet.
vim.api.nvim_create_autocmd("PackChanged", {
  group = group,
  callback = function(ev)
    local data = ev.data
    if not vim.list_contains(PLUGINS, data.spec.name) then
      return
    end
    if data.kind ~= "install" and data.kind ~= "update" then
      return
    end
    state.update_pending = true
    if state.loaded and state.install ~= "running" then
      vim.schedule(run_update)
    end
  end,
})

pcall(vim.pack.add, {
  -- Core has no parser installer/updater, bundled queries or TS indentation.
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", },
  -- Core has no syntax-aware text objects or function/class jumps.
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", },
}, {
  confirm = false,
  -- Register only; loaded on the first supported FileType.
  load = function() end,
})

-- Loads both plugins, trying once per session. :packadd of a missing
-- package raises no error, so success is checked on 'runtimepath'.
local function ensure_loaded()
  if state.loaded == nil then
    state.loaded = true
    for _, name in ipairs(PLUGINS) do
      local ok = pcall(vim.cmd.packadd, name)
      local file = ("lua/%s/init.lua"):format(name)
      if not ok or #vim.api.nvim_get_runtime_file(file, false) == 0 then
        state.loaded = false
      end
    end
  end
  return state.loaded
end

local function has_query(lang, kind)
  local ok, files = pcall(vim.treesitter.query.get_files, lang, kind)
  return ok and #files > 0
end

-- Text objects and jumps --------------------------------------------------

local SELECTS = {
  { "af", "@function.outer",  "Around function", },
  { "if", "@function.inner",  "Inside function", },
  { "ac", "@class.outer",     "Around class", },
  { "ic", "@class.inner",     "Inside class", },
  { "aa", "@parameter.outer", "Around parameter", },
  { "ia", "@parameter.inner", "Inside parameter", },
}

local JUMPS = {
  { "]f", "goto_next_start",     "Next function start", },
  { "[f", "goto_previous_start", "Previous function start", },
}

-- In a diff window these keep the built-in change jumps.
local CLASS_JUMPS = {
  { "]c", "goto_next_start",     "Next class start (diff: next change)", },
  {
    "[c",
    "goto_previous_start",
    "Previous class start (diff: previous change)",
  },
}

local MAPPED = {
  { { "x", "o", },      { "af", "if", "ac", "ic", "aa", "ia", }, },
  { { "n", "x", "o", }, { "]f", "[f", "]c", "[c", }, },
}

-- Jump to the start of the next/previous capture; used by ]c/[c via <Cmd>.
function M.jump(method, capture)
  pcall(function()
    require("nvim-treesitter-textobjects.move")[method](
      capture,
      "textobjects"
    )
  end)
end

local function map_textobjects(buf, lang)
  if not has_query(lang, "textobjects") then
    return
  end
  for _, s in ipairs(SELECTS) do
    vim.keymap.set({ "x", "o", }, s[1], function()
      pcall(function()
        require("nvim-treesitter-textobjects.select").select_textobject(
          s[2],
          "textobjects"
        )
      end)
    end, { buffer = buf, desc = s[3], })
  end
  for _, j in ipairs(JUMPS) do
    vim.keymap.set({ "n", "x", "o", }, j[1], function()
      M.jump(j[2], "@function.outer")
    end, { buffer = buf, desc = j[3], })
  end
  for _, j in ipairs(CLASS_JUMPS) do
    local cmd = ("<Cmd>lua require(\"config.treesitter\").jump(%q, %q)<CR>")
      :format(j[2], "@class.outer")
    vim.keymap.set({ "n", "x", "o", }, j[1], function()
      -- Non-recursive: the returned key is the built-in diff jump.
      return vim.wo.diff and j[1] or cmd
    end, { buffer = buf, expr = true, desc = j[3], })
  end
end

local function unmap_textobjects(buf)
  for _, group_ in ipairs(MAPPED) do
    for _, mode in ipairs(group_[1]) do
      for _, lhs in ipairs(group_[2]) do
        pcall(vim.keymap.del, mode, lhs, { buffer = buf, })
      end
    end
  end
end

-- Buffer attachment -------------------------------------------------------

-- Enables what the language's queries support. Returns false when the
-- parser cannot be loaded (yet).
local function attach(buf, lang)
  if not pcall(vim.treesitter.start, buf, lang) then
    return false
  end
  if has_query(lang, "folds") then
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      local wo = vim.wo[win][0]
      wo.foldmethod = "expr"
      wo.foldexpr = FOLDEXPR
      wo.foldlevel = 99
    end
  end
  -- The indent expression and the mappings need the plugins; installed
  -- queries are on 'runtimepath' even when the plugin folders are missing.
  if state.loaded then
    if has_query(lang, "indents") then
      vim.bo[buf].indentexpr = INDENTEXPR
    end
    map_textobjects(buf, lang)
  end
  vim.b[buf].config_treesitter = lang
  return true
end

-- Undoes attach() when the filetype changes to an unsupported one. Runs
-- after the new filetype's ftplugin and indent script, so only values this
-- module set are reset.
local function detach(buf)
  local lang = vim.b[buf].config_treesitter
  local hl = vim.treesitter.highlighter.active[buf]
  if hl and hl.tree:lang() == lang then
    pcall(vim.treesitter.stop, buf)
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    local wo = vim.wo[win][0]
    if wo.foldexpr == FOLDEXPR then
      wo.foldmethod = vim.go.foldmethod
      wo.foldexpr = vim.go.foldexpr
      wo.foldlevel = vim.go.foldlevel
    end
  end
  if vim.bo[buf].indentexpr == INDENTEXPR then
    vim.bo[buf].indentexpr = vim.go.indentexpr
  end
  unmap_textobjects(buf)
  vim.b[buf].config_treesitter = nil
end

-- Parser installation -----------------------------------------------------

local function finish_install()
  state.install = "done"
  local pending = state.pending
  state.pending = {}
  for buf in pairs(pending) do
    if vim.api.nvim_buf_is_valid(buf) then
      local lang = FILETYPES[vim.bo[buf].filetype]
      if lang then
        attach(buf, lang)
      end
    end
  end
  run_update()
end

-- Installs all missing parsers once per session (silent no-op when all
-- exist), then runs an update a plugin change may have requested.
local function install_parsers()
  if state.install == "running" then
    return
  end
  if state.install == "done" then
    run_update()
    return
  end
  local missing = missing_tools()
  if #missing > 0 then
    warn_missing(missing)
    state.install = "done"
    run_update()
    return
  end
  state.install = "running"
  local ok = pcall(function()
    require("nvim-treesitter").install(LANGUAGES):await(function()
      vim.schedule(finish_install)
    end)
  end)
  if not ok then
    finish_install()
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(args)
    local buf = args.buf
    local lang = FILETYPES[args.match]
    if not lang then
      if vim.b[buf].config_treesitter then
        detach(buf)
      end
      return
    end
    local loaded = ensure_loaded()
    if not attach(buf, lang) and state.install ~= "done" then
      state.pending[buf] = true
    end
    if loaded then
      install_parsers()
    end
  end,
})

return M
