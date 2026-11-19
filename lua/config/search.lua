-- Search position label, search-key wrappers and <Esc> to clear highlights.

local M = {}

local ns = vim.api.nvim_create_namespace("config_search_count")
local group = vim.api.nvim_create_augroup("config_search_count", {
  clear = true,
})

-- The single label: the buffer holding it and its extmark id.
local state = { buf = nil, id = nil, }

local function set_highlight()
  vim.api.nvim_set_hl(0, "SearchCountLabel", {
    link = "Comment",
    default = true,
  })
end

set_highlight()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = set_highlight,
})

-- Label text for a searchcount() result, or nil when no label is shown.
local function label_text(sc)
  if sc.exact_match ~= 1 or sc.total == 0 then
    return nil
  end
  if sc.incomplete == 1 then
    return "[?/?]"
  end
  if sc.incomplete == 2 then
    local cap = ">" .. sc.maxcount
    local current = sc.current > sc.maxcount and cap or sc.current
    return ("[%s/%s]"):format(current, cap)
  end
  return ("[%d/%d]"):format(sc.current, sc.total)
end

function M.clear()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    pcall(vim.api.nvim_buf_del_extmark, state.buf, ns, state.id)
  end
  state.buf, state.id = nil, nil
end

function M.refresh()
  M.clear()
  if vim.v.hlsearch == 0 then
    return
  end
  local ok, sc = pcall(vim.fn.searchcount, {
    recompute = true,
    maxcount = 999,
    timeout = 100,
  })
  if not ok or vim.tbl_isempty(sc) then
    return
  end
  local text = label_text(sc)
  if not text then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local id_ok, id = pcall(vim.api.nvim_buf_set_extmark, buf, ns, row, 0, {
    virt_text = { { text, "SearchCountLabel", }, },
    virt_text_pos = "right_align",
  })
  if id_ok then
    state.buf, state.id = buf, id
  end
end

-- Search keys keep their native behaviour (counts, offsets, errors); the
-- label is refreshed once the jump has happened.
local search_keys = {
  { "n",  "Next search match", },
  { "N",  "Previous search match", },
  { "*",  "Search word forward", },
  { "#",  "Search word backward", },
  { "g*", "Search partial word forward", },
  { "g#", "Search partial word backward", },
}

for _, key in ipairs(search_keys) do
  vim.keymap.set("n", key[1], function()
    vim.schedule(M.refresh)
    return key[1]
  end, { expr = true, desc = key[2], })
end

vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = group,
  callback = function(args)
    if vim.v.event.abort then
      return
    end
    if args.match == "/" or args.match == "?" then
      vim.schedule(M.refresh)
    elseif args.match == ":" then
      -- Covers a typed :nohlsearch.
      vim.schedule(function()
        if vim.v.hlsearch == 0 then
          M.clear()
        end
      end)
    end
  end,
})

-- Ordinary cursor motions deliberately leave the label alone.
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufLeave", }, {
  group = group,
  callback = function(args)
    if args.buf == state.buf then
      M.clear()
    end
  end,
})

vim.keymap.set("n", "<Esc>", function()
  vim.cmd.nohlsearch()
  M.clear()
end, { desc = "Clear search highlights", })

return M
