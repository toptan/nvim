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
