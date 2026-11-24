-- <leader>ld / <leader>lD: buffer or workspace diagnostics in the location
-- list, ordered and coloured by severity, and <Esc> to close a location list.
-- vim.diagnostic and vim.lsp are only touched when a key is pressed.

-- Display lines and highlight ranges per location list id; read by the
-- list's quickfixtextfunc and by the decoration provider.
local lists = {}
local ns = vim.api.nvim_create_namespace("config_diagnostic_list")
local group = vim.api.nvim_create_augroup("config_diagnostic_list", {
  clear = true,
})

-- Indexed by vim.diagnostic.severity (1 = ERROR … 4 = HINT).
local severities = {
  { label = "error",   type = "E", hl = "DiagnosticError", },
  { label = "warning", type = "W", hl = "DiagnosticWarn", },
  { label = "info",    type = "I", hl = "DiagnosticInfo", },
  { label = "hint",    type = "N", hl = "DiagnosticHint", },
}

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
-- line and column. Diagnostics that are turned off are left out.
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

  local items, record = {}, { lines = {}, hl = {}, }
  for i, e in ipairs(entries) do
    local d = e.d
    local sev = severities[d.severity] or severities[1]
    local message = d.message:gsub("\r?\n", " ")
    local prefix = ("%s|%d col %d "):format(e.file, d.lnum + 1, d.col + 1)
    local label_end = #prefix + #sev.label
    local line = prefix .. sev.label .. "| " .. message
    record.lines[i] = line
    record.hl[i] = {
      group = sev.hl,
      label = { #prefix, label_end, },
      msg = { label_end + 2, #line, },
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
    vim.notify(empty_msg, vim.log.levels.INFO)
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
