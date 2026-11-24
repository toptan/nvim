-- Diagnostics: display (virtual text / virtual lines / popup style), the
-- three toggles, and <leader>ld / <leader>lD to list buffer or workspace
-- diagnostics in the location list, ordered and coloured by severity, with
-- <Esc> to close a location list. vim.diagnostic and vim.lsp are only touched
-- when diagnostics arrive or a key is pressed.

local M = {}

local group = vim.api.nvim_create_augroup("config_diagnostics", {
  clear = true,
})

local did_setup = false

-- Apply the initial display once. Deferred until it is needed so that
-- vim.diagnostic is not loaded at startup.
function M.setup()
  if did_setup then
    return
  end
  did_setup = true
  -- The popup's title replaces the default "Diagnostics:" header line.
  vim.diagnostic.config({
    virtual_text = true,
    virtual_lines = false,
    float = { title = " Diagnostics ", header = "", source = true, },
  })
end

-- Diagnostics from any source, not only lua_ls, get the initial display.
-- Creating the autocommand does not load vim.diagnostic.
vim.api.nvim_create_autocmd("DiagnosticChanged", {
  group = group,
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

-- Diagnostics list --------------------------------------------------------

-- Display lines and highlight ranges per location list id; read by the
-- list's quickfixtextfunc and by the decoration provider.
local lists = {}
local ns = vim.api.nvim_create_namespace("config_diagnostics")

-- Indexed by vim.diagnostic.severity (1 = ERROR … 4 = HINT).
local severities = {
  { label = "error",   type = "E", hl = "DiagnosticError", },
  { label = "warning", type = "W", hl = "DiagnosticWarn", },
  { label = "info",    type = "I", hl = "DiagnosticInfo", },
  { label = "hint",    type = "N", hl = "DiagnosticHint", },
}
-- Labels are padded to the longest one ("warning") so messages line up.
local LABEL_WIDTH = 7

-- The file window: the current one, or the owner of the location list the
-- cursor is in.
local function target_win()
  if vim.fn.win_gettype() == "loclist" then
    local owner = vim.fn.getloclist(0, { filewinid = 0, }).filewinid
    if owner ~= 0 and vim.api.nvim_win_is_valid(owner) then
      return owner
    end
  end
  return vim.api.nvim_get_current_win()
end

local function file_name(bufnr)
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":~:.")
  return name ~= "" and name or "[No Name]"
end

-- Quickfix items and the matching list record, sorted by severity, file,
-- line and column. Diagnostics that are turned off are left out. Each
-- display line is "<location><pad> <label><pad>| <message>": locations are
-- padded to the widest one in the list (by screen width) so labels share a
-- column, and labels to LABEL_WIDTH so messages share a column.
local function build(diagnostics)
  local entries = {}
  for _, d in ipairs(diagnostics) do
    if vim.diagnostic.is_enabled({ bufnr = d.bufnr, ns_id = d.namespace, }) then
      entries[#entries + 1] = { d = d, file = file_name(d.bufnr), }
    end
  end
  table.sort(entries, function(a, b)
    if a.d.severity ~= b.d.severity then
      return a.d.severity < b.d.severity
    elseif a.file ~= b.file then
      return a.file < b.file
    elseif a.d.lnum ~= b.d.lnum then
      return a.d.lnum < b.d.lnum
    end
    return a.d.col < b.d.col
  end)

  local loc_width = 0
  for _, e in ipairs(entries) do
    e.loc = ("%s|%d col %d"):format(e.file, e.d.lnum + 1, e.d.col + 1)
    e.loc_width = vim.fn.strdisplaywidth(e.loc)
    loc_width = math.max(loc_width, e.loc_width)
  end

  local items, record = {}, { lines = {}, hl = {}, }
  for i, e in ipairs(entries) do
    local d = e.d
    local sev = severities[d.severity] or severities[1]
    local message = d.message:gsub("\r?\n", " ")
    local prefix = e.loc .. (" "):rep(loc_width - e.loc_width + 1)
    local label = sev.label .. (" "):rep(LABEL_WIDTH - #sev.label)
    local line = prefix .. label .. "| " .. message
    record.lines[i] = line
    record.hl[i] = {
      group = sev.hl,
      label = { #prefix, #prefix + #sev.label, },
      msg = { #prefix + LABEL_WIDTH + 2, #line, },
    }
    items[i] = {
      bufnr = d.bufnr,
      lnum = d.lnum + 1,
      col = d.col + 1,
      end_lnum = d.end_lnum and d.end_lnum + 1 or nil,
      end_col = d.end_col and d.end_col + 1 or nil,
      text = message,
      type = sev.type,
      valid = 1,
    }
  end
  return items, record
end

local function qftf(info)
  local record = lists[info.id]
  if not record then
    return {}
  end
  local out = {}
  for i = info.start_idx, info.end_idx do
    out[#out + 1] = record.lines[i] or ""
  end
  return out
end

-- Colours are drawn on every redraw, so they follow :colorscheme and survive
-- :lclose/:lopen and :lolder/:lnewer; other lists are left alone.
local provider_set = false
local drawing -- list record of the window being drawn

local function ensure_provider()
  if provider_set then
    return
  end
  provider_set = true
  vim.api.nvim_set_decoration_provider(ns, {
    on_win = function(_, win, buf)
      if vim.bo[buf].buftype ~= "quickfix" then
        return false
      end
      drawing = lists[vim.fn.getloclist(win, { id = 0, }).id]
      return drawing ~= nil
    end,
    on_line = function(_, _, buf, row)
      local h = drawing and drawing.hl[row + 1]
      if not h then
        return
      end
      for _, range in ipairs({ h.label, h.msg, }) do
        if range[2] > range[1] then
          vim.api.nvim_buf_set_extmark(buf, ns, row, range[1], {
            end_col = range[2],
            hl_group = h.group,
            ephemeral = true,
            priority = 200,
            strict = false,
          })
        end
      end
    end,
  })
end

-- Fill the location list of `win` and focus it, or say there is nothing.
local function show(win, title, diagnostics, empty_msg)
  local items, record = build(diagnostics)
  if #items == 0 then
    notify(empty_msg)
    return
  end
  -- The record must exist before the items arrive: an open list window is
  -- re-rendered (calling qftf) as soon as they are set.
  local id = vim.fn.getloclist(win, { id = 0, }).id
  if not lists[id] then
    vim.fn.setloclist(win, {}, " ", { title = title, })
    id = vim.fn.getloclist(win, { id = 0, }).id
  end
  lists[id] = record
  ensure_provider()
  vim.fn.setloclist(win, {}, "r", {
    id = id,
    title = title,
    items = items,
    quickfixtextfunc = qftf,
  })
  vim.api.nvim_set_current_win(win)
  vim.cmd.lopen()
end

-- Ask servers that support pull workspace diagnostics for them and wait at
-- most 2 s for the answers. lua_ls pushes whole-project diagnostics by
-- itself and clangd has none, so today this returns at once.
local function request_workspace(bufnr)
  if not package.loaded["vim.lsp"] then
    return
  end
  local asked = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, })) do
    if client:supports_method("workspace/diagnostic") then
      vim.lsp.buf.workspace_diagnostics({ client_id = client.id, })
      asked[#asked + 1] = client
    end
  end
  if #asked == 0 then
    return
  end
  vim.wait(2000, function()
    for _, client in ipairs(asked) do
      for _, req in pairs(client.requests) do
        if req.method == "workspace/diagnostic" and req.type == "pending" then
          return false
        end
      end
    end
    return true
  end, 50)
end

vim.keymap.set("n", "<leader>ld", function()
  local win = target_win()
  show(win, "Diagnostics", vim.diagnostic.get(vim.api.nvim_win_get_buf(win)),
    "No diagnostics")
end, { desc = "Buffer diagnostics", })

vim.keymap.set("n", "<leader>lD", function()
  local win = target_win()
  request_workspace(vim.api.nvim_win_get_buf(win))
  if not vim.api.nvim_win_is_valid(win) then
    win = target_win()
  end
  show(win, "Workspace diagnostics", vim.diagnostic.get(),
    "No workspace diagnostics")
end, { desc = "Workspace diagnostics", })

-- <Esc> in any location list window closes it and returns to its file
-- window; quickfix windows keep the global <Esc>. <CR> is left built-in.
-- It lives here because it exists for the diagnostics list.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "qf",
  callback = function(args)
    if vim.fn.win_gettype() ~= "loclist" then
      return
    end
    vim.keymap.set("n", "<Esc>", function()
      local owner = vim.fn.getloclist(0, { filewinid = 0, }).filewinid
      vim.cmd.lclose()
      if owner ~= 0 and vim.api.nvim_win_is_valid(owner) then
        vim.api.nvim_set_current_win(owner)
      end
    end, { buffer = args.buf, desc = "Close location list", })
  end,
})

return M
