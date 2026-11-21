-- Notifications: vim.notify shown in a popup in the top right corner.

local M = {}

-- How long each notification stays in the popup, in milliseconds. Edit
-- this value and restart Neovim to change it.
local TIMEOUT_MS = 3000
-- Most notifications shown at once; a newer one drops the oldest.
local MAX_ENTRIES = 3
local TITLE = " Notifications "
-- Popup width cap as a share of the editor width.
local MAX_WIDTH_RATIO = 0.4

local api = vim.api
local levels = vim.log.levels

---@class config.notifications.Entry
---@field lines string[]
---@field hl string
---@field timer? uv.uv_timer_t

local entries = {} ---@type config.notifications.Entry[]
local pending = {} ---@type config.notifications.Entry[]
local held = {} ---@type config.notifications.Entry[]
local buf ---@type integer?
local win ---@type integer?
local ns = api.nvim_create_namespace("config_notifications")
local group = api.nvim_create_augroup("config_notifications", { clear = true, })

-- History highlight for the popup highlight of each level.
local echo_hl = {
  DiagnosticError = "ErrorMsg",
  DiagnosticWarn = "WarningMsg",
}

---@param level integer?
---@return string
local function level_hl(level)
  if level == levels.ERROR then
    return "DiagnosticError"
  elseif level == levels.WARN then
    return "DiagnosticWarn"
  end
  return "DiagnosticInfo"
end

---@return config.notifications.Entry?
local function new_entry(msg, level)
  local lines = vim.split(tostring(msg), "\n", { plain = true, })
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end
  if #lines == 0 then
    return nil
  end
  return { lines = lines, hl = level_hl(level), }
end

-- Split a line into pieces no wider than `width` display cells.
---@return string[]
local function pieces(line, width)
  local result = {}
  repeat
    local n = math.max(1, math.min(width, vim.fn.strchars(line)))
    local piece = vim.fn.strcharpart(line, 0, n)
    while n > 1 and vim.fn.strdisplaywidth(piece) > width do
      n = n - 1
      piece = vim.fn.strcharpart(line, 0, n)
    end
    result[#result + 1] = piece
    line = vim.fn.strcharpart(line, n)
  until line == ""
  return result
end

-- Add to :messages without leaving the text on the command line. Each piece
-- fits the command line and is cleared at once, so there is never a
-- "Press ENTER" prompt.
---@param entry config.notifications.Entry
local function write_history(entry)
  local hl = echo_hl[entry.hl]
  local width = math.max(vim.v.echospace, 10)
  for _, line in ipairs(entry.lines) do
    for _, piece in ipairs(pieces(line, width)) do
      api.nvim_echo({ { piece, hl, }, }, true, {})
      api.nvim_echo({ { "", }, }, false, {})
    end
  end
end

local history

local function flush_held()
  local list = held
  held = {}
  for _, entry in ipairs(list) do
    history(entry)
  end
end

-- While a command line is being typed, hold the write; after leaving it,
-- wait for a key so the command's output stays readable until then.
---@param entry config.notifications.Entry
history = function(entry)
  if not vim.startswith(vim.fn.mode(), "c") then
    write_history(entry)
    return
  end
  held[#held + 1] = entry
  if #held > 1 then
    return
  end
  api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    once = true,
    callback = function()
      local done = false
      vim.on_key(function()
        if done then
          return
        end
        done = true
        vim.schedule(function()
          vim.on_key(nil, ns)
          flush_held()
        end)
      end, ns)
    end,
  })
end

local function tabline_rows()
  local stal = vim.o.showtabline
  if stal == 2 or (stal == 1 and #api.nvim_list_tabpages() > 1) then
    return 1
  end
  return 0
end

local function border()
  local value = vim.o.winborder
  if value == "" then
    return "rounded"
  elseif value:find(",") then
    return vim.split(value, ",", { plain = true, })
  end
  return value
end

-- Window config for the current entries, and the text width. The width is
-- taken from the notification text only, never from separators.
---@return vim.api.keyset.win_config, integer
local function layout()
  local columns = vim.o.columns
  local max_width = math.max(1, math.min(
    math.floor(columns * MAX_WIDTH_RATIO), columns - 2))
  local width = vim.fn.strdisplaywidth(TITLE)
  for _, entry in ipairs(entries) do
    for _, line in ipairs(entry.lines) do
      width = math.max(width, vim.fn.strdisplaywidth(line) + 1)
    end
  end
  width = math.min(width, max_width)

  local height = #entries - 1
  for _, entry in ipairs(entries) do
    for _, line in ipairs(entry.lines) do
      local cells = vim.fn.strdisplaywidth(line)
      height = height + math.max(1, math.ceil(cells / width))
    end
  end
  local row = tabline_rows()
  local max_height = math.max(1, vim.o.lines - row - 2 - vim.o.cmdheight)

  return {
    relative = "editor",
    anchor = "NE",
    row = row,
    col = columns,
    width = width,
    height = math.min(height, max_height),
    border = border(),
    title = TITLE,
    focusable = false,
    style = "minimal",
    zindex = 250,
  }, width
end

-- The screen is not redrawn on its own while a command line is typed.
local function redraw_in_cmdline()
  if vim.startswith(vim.fn.mode(), "c") then
    vim.cmd.redraw()
  end
end

local function close()
  if win and api.nvim_win_is_valid(win) then
    api.nvim_win_close(win, true)
    redraw_in_cmdline()
  end
  win = nil
end

local function render()
  if #entries == 0 or #api.nvim_list_uis() == 0 then
    close()
    return
  end
  if not (buf and api.nvim_buf_is_valid(buf)) then
    buf = api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "hide"
  end

  local config, width = layout()
  local text = {} ---@type string[]
  local marks = {} ---@type [integer, integer, string][]
  for i, entry in ipairs(entries) do
    if i > 1 then
      text[#text + 1] = string.rep("─", width)
      marks[#marks + 1] = { #text - 1, #text - 1, "FloatBorder", }
    end
    local first = #text
    vim.list_extend(text, entry.lines)
    marks[#marks + 1] = { first, #text - 1, entry.hl, }
  end

  api.nvim_buf_set_lines(buf, 0, -1, false, text)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, mark in ipairs(marks) do
    api.nvim_buf_set_extmark(buf, ns, mark[1], 0, {
      end_row = mark[2],
      end_col = #text[mark[2] + 1],
      hl_group = mark[3],
    })
  end

  if win and api.nvim_win_is_valid(win) then
    api.nvim_win_set_config(win, config)
  else
    config.noautocmd = true
    win = api.nvim_open_win(buf, false, config)
  end
  vim.wo[win].wrap = true
  -- Show from the top, scrolling only when needed to keep the newest
  -- (last) entry visible.
  api.nvim_win_call(win, function()
    vim.fn.winrestview({ topline = 1, })
  end)
  api.nvim_win_set_cursor(win, { #text, 0, })
  redraw_in_cmdline()
end

---@param entry config.notifications.Entry
local function stop(entry)
  local timer = entry.timer
  entry.timer = nil
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
end

---@param entry config.notifications.Entry
local function remove(entry)
  for i, e in ipairs(entries) do
    if e == entry then
      table.remove(entries, i)
      pcall(render)
      return
    end
  end
end

---@param entry config.notifications.Entry
local function add(entry)
  while #entries >= MAX_ENTRIES do
    stop(table.remove(entries, 1))
  end
  entries[#entries + 1] = entry
  entry.timer = vim.defer_fn(function()
    remove(entry)
  end, TIMEOUT_MS)
  render()
end

-- Every notification is recorded in :messages; it is shown in the popup once
-- startup has finished and a UI is attached. All work is scheduled so this
-- is safe from fast events and under textlock.
---@diagnostic disable-next-line: duplicate-set-field
vim.notify = function(msg, level, _)
  local entry = new_entry(msg, level)
  if not entry then
    return
  end
  vim.schedule(function()
    history(entry)
    if vim.v.vim_did_enter == 0 then
      pending[#pending + 1] = entry
    elseif #api.nvim_list_uis() > 0 then
      pcall(add, entry)
    end
  end)
end

api.nvim_create_autocmd("VimEnter", {
  group = group,
  once = true,
  callback = function()
    local list = pending
    pending = {}
    if #api.nvim_list_uis() == 0 then
      return
    end
    for _, entry in ipairs(list) do
      pcall(add, entry)
    end
  end,
})

api.nvim_create_autocmd("VimResized", {
  group = group,
  callback = function()
    if win and api.nvim_win_is_valid(win) then
      pcall(render)
    end
  end,
})

return M
