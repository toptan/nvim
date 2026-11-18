-- Colour scheme and background transparency.

local transparent_groups = {
  "Normal",
  "NormalNC",
  "SignColumn",
  "LineNr",
  "CursorLineNr",
  "FoldColumn",
  "EndOfBuffer",
}

-- Re-apply on every scheme load, including the reload triggered when the
-- terminal's light/dark background is detected or changes.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("config_transparency", { clear = true, }),
  callback = function()
    for _, name in ipairs(transparent_groups) do
      local hl = vim.api.nvim_get_hl(0, { name = name, link = false, })
      vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", hl, {
        bg = "NONE",
        ctermbg = "NONE",
      }))
    end
  end,
})

-- 'background' is left to terminal detection; catppuccin picks its palette
-- from it.
pcall(vim.cmd.colorscheme, "catppuccin")
