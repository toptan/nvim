-- General-purpose key mappings.

-- File buffers (listed, not help/quickfix/terminal/explorer) in the order
-- they were opened; buffer numbers grow with every new buffer.
local function file_buffers()
  return vim.tbl_filter(function(buf)
    return vim.bo[buf].buflisted and vim.bo[buf].buftype == ""
  end, vim.api.nvim_list_bufs())
end

-- Switch to the next (step = 1) or previous (step = -1) file buffer,
-- wrapping around. From a special buffer, go to the nearest file buffer in
-- that direction.
local function cycle(step)
  local bufs = file_buffers()
  local current = vim.api.nvim_get_current_buf()
  if #bufs == 0 or (#bufs == 1 and bufs[1] == current) then
    return
  end
  if step < 0 then
    bufs = vim.fn.reverse(bufs)
  end
  local target = bufs[1]
  for _, buf in ipairs(bufs) do
    if (step > 0 and buf > current) or (step < 0 and buf < current) then
      target = buf
      break
    end
  end
  vim.cmd.buffer(target)
end

-- <Tab> also replaces <C-i> (jump forward) in terminals; this is accepted
-- and jump-forward is deliberately not remapped. <C-o> is untouched.
vim.keymap.set("n", "<Tab>", function()
  cycle(1)
end, { desc = "Next buffer", })
vim.keymap.set("n", "<S-Tab>", function()
  cycle(-1)
end, { desc = "Previous buffer", })

-- One-key window moves in Normal mode, the same as <C-w>h/j/k/l (which
-- still work, and take a count). <C-l> no longer clears and redraws the
-- screen: use :redraw! instead. Other modes keep their meanings.
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window", })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window", })

-- Visual-mode indent keeps the selection, so > and < can be repeated. A count
-- is honoured (3>). Selection columns are kept, not the selected characters.
vim.keymap.set("x", ">", ">gv", { desc = "Indent selection", })
vim.keymap.set("x", "<", "<gv", { desc = "Dedent selection", })

-- Move the current line (Normal) or the selected lines (Visual) down
-- (dir = 1) or up (dir = -1) by [count] lines, stopping at the buffer edge.
-- :move keeps indentation and registers and is one undo step. In Visual mode
-- the moved lines are reselected in the same visual mode.
local function move_lines(dir)
  local count = vim.v.count1
  local visual = vim.fn.mode():match("^[vV\22]") ~= nil
  local top, bottom = vim.fn.line("."), vim.fn.line(".")
  if visual then
    top, bottom = vim.fn.line("v"), vim.fn.line(".")
    if top > bottom then
      top, bottom = bottom, top
    end
    vim.cmd("normal! \27")
  end
  local target
  if dir > 0 and bottom < vim.fn.line("$") then
    target = math.min(vim.fn.line("$"), bottom + count)
  elseif dir < 0 and top > 1 then
    target = math.max(0, top - count - 1)
  end
  if target then
    vim.cmd(("silent keepjumps %d,%dmove %d"):format(top, bottom, target))
  end
  if visual then
    vim.cmd("normal! gv")
  end
end

-- ∆ and ˚ are what Option+j / Option+k type on the macOS US layout when the
-- terminal does not send Option as Meta. They are not mapped in Insert mode,
-- so they can still be typed as text.
local move_keys = {
  { "<M-j>", 1, }, { "∆", 1, },
  { "<M-k>", -1, }, { "˚", -1, },
}
for _, key in ipairs(move_keys) do
  local lhs, dir = key[1], key[2]
  local where = dir > 0 and "down" or "up"
  vim.keymap.set("x", lhs, function()
    move_lines(dir)
  end, { desc = "Move selection " .. where, })
  vim.keymap.set("n", lhs, function()
    move_lines(dir)
  end, { desc = "Move line " .. where, })
end
