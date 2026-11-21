-- Insert-mode completion by mini.completion with its defaults: a menu opens
-- by itself in every buffer (server suggestions first, then buffer words),
-- with item info and signature help windows. Loaded on first Insert mode.
-- IDE-style keys: <Tab>/<S-Tab> to move, <CR> to accept, <C-Space> to open.
-- Plugin: core 'autocomplete' with vim.lsp.completion needed ~250 lines of
-- workarounds to merge server and buffer suggestions, re-ask the server as
-- a word grows and handle trigger characters; the plugin does this itself.

local M = {}

local loaded = false

vim.api.nvim_create_autocmd("InsertEnter", {
  group = vim.api.nvim_create_augroup("config_completion", { clear = true, }),
  once = true,
  callback = function()
    loaded = pcall(vim.pack.add, {
      "https://github.com/nvim-mini/mini.completion",
    }, { confirm = false, })
    if loaded then
      loaded = pcall(function()
        require("mini.completion").setup()
      end)
    end
    if not loaded then
      vim.schedule(function()
        vim.notify("mini.completion unavailable: using built-in completion",
          vim.log.levels.WARN)
      end)
      return
    end
    -- The plugin sets this on BufEnter, which for this buffer came earlier.
    vim.bo.completefunc = "v:lua.MiniCompletion.completefunc_lsp"
  end,
})

local function pum_visible()
  return vim.fn.pumvisible() == 1
end

-- <Down>/<Up> select without inserting (:h popupmenu-keys), unlike
-- <C-n>/<C-p>. With the menu closed these reproduce Neovim's default snippet
-- jumps.
local function tab(key, menu_key, direction)
  return function()
    if pum_visible() then
      return menu_key
    end
    if vim.snippet.active({ direction = direction, }) then
      return ("<Cmd>lua vim.snippet.jump(%d)<CR>"):format(direction)
    end
    return key
  end
end

vim.keymap.set("i", "<Tab>", tab("<Tab>", "<Down>", 1), {
  expr = true,
  desc = "Next completion item, snippet jump or Tab",
})
vim.keymap.set("i", "<S-Tab>", tab("<S-Tab>", "<Up>", -1), {
  expr = true,
  desc = "Previous completion item, snippet jump or S-Tab",
})

vim.keymap.set("i", "<CR>", function()
  if not pum_visible() then
    return "<CR>"
  end
  if vim.fn.complete_info({ "selected", }).selected ~= -1 then
    return "<C-y>"
  end
  return "<C-e><CR>"
end, { expr = true, desc = "Accept selected completion item or new line", })

-- The plugin maps <C-Space>; terminals usually send Ctrl+Space as <C-@>.
vim.keymap.set("i", "<C-@>", function()
  if loaded then
    MiniCompletion.complete_twostage()
  end
end, { desc = "Trigger completion", })

return M
