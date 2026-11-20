-- Colour scheme, background transparency and the float border colour.

local transparent_groups = {
  "Normal",
  "NormalNC",
  "SignColumn",
  "LineNr",
  "CursorLineNr",
  "FoldColumn",
  "EndOfBuffer",
}

-- catppuccin draws float borders almost in the background colour, so the
-- border takes the title colour on the float's own background instead.
-- Left as the scheme defined it when the title has no colour.
local function set_float_border()
  local title = vim.api.nvim_get_hl(0, { name = "FloatTitle", link = false, })
  if not title.fg then
    return
  end
  local float = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false, })
  vim.api.nvim_set_hl(0, "FloatBorder", {
    fg = title.fg,
    ctermfg = title.ctermfg,
    bg = float.bg,
    ctermbg = float.ctermbg,
  })
end

-- Re-apply on every scheme load, including the reload triggered when the
-- terminal's light/dark background is detected or changes. The group also
-- sets the float border colour.
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
    set_float_border()
  end,
})

-- 'background' is left to terminal detection; catppuccin picks its palette
-- from it.
pcall(vim.cmd.colorscheme, "catppuccin")
