-- Formatting CMake buffers with gersemi (<leader>lf). Loaded on first use.

local M = {}

local timeout_ms = 5000

local function warn(msg)
  vim.notify(msg, vim.log.levels.WARN)
end

-- Replace only the lines that differ, last hunk first so earlier hunks keep
-- their line numbers. The cursor, marks and folds outside changed lines stay
-- where they were, and an unchanged buffer is not touched at all.
local function apply(bufnr, old, new)
  local a = table.concat(old, "\n") .. "\n"
  local b = table.concat(new, "\n") .. "\n"
  if a == b then
    return
  end
  local hunks = vim.text.diff(a, b, {
    result_type = "indices",
  }) --[[@as integer[][] ]]
  for i = #hunks, 1, -1 do
    local start_a, count_a, start_b, count_b = unpack(hunks[i])
    local lines = vim.list_slice(new, start_b, start_b + count_b - 1)
    -- A pure insertion (count_a == 0) goes after line start_a.
    local first = count_a == 0 and start_a or start_a - 1
    vim.api.nvim_buf_set_lines(bufnr, first, first + count_a, false, lines)
  end
end

-- Directory gersemi runs in, and the path it looks up .gersemirc from.
local function location(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return nil, vim.fn.getcwd()
  end
  local dir = vim.fs.dirname(name)
  if not vim.uv.fs_stat(dir) then
    dir = vim.fn.getcwd()
  end
  return name, dir
end

-- Format the whole buffer from its current, possibly unsaved, content. The
-- project's .gersemirc applies; no style options are passed. On failure the
-- buffer is left as it is and one warning explains why.
function M.format(bufnr)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if vim.fn.executable("gersemi") == 0 then
    warn("gersemi is not installed")
    return
  end

  local old = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local path, cwd = location(bufnr)
  local cmd = { "gersemi", }
  if path then
    vim.list_extend(cmd, { "--stdin-filepath", path, })
  end
  cmd[#cmd + 1] = "-"

  local ok, proc = pcall(vim.system, cmd, {
    stdin = table.concat(old, "\n") .. "\n",
    cwd = cwd,
    text = true,
  })
  if not ok then
    warn("gersemi: " .. tostring(proc))
    return
  end
  local result = proc:wait(timeout_ms)

  if result.code == 124 then
    warn("gersemi timed out")
    return
  end
  -- On success stderr only holds warnings (e.g. unknown custom commands).
  if result.code ~= 0 then
    local reason = (result.stderr or ""):match("[^\n]*%S[^\n]*")
    warn("gersemi: " .. (reason or ("exited with code " .. result.code)))
    return
  end

  local new = vim.split(result.stdout or "", "\n", { plain = true, })
  if new[#new] == "" then
    new[#new] = nil
  end
  apply(bufnr, old, new)
end

return M
