local add = vim.pack.add

-- Ayu colorscheme


-- Conform code formatting plugin
add({ "https://github.com/stevearc/conform.nvim" })

-- See also:
-- - `:h Conform`
-- - `:h conform-options`
-- - `:h conform-formatters`
require("conform").setup({
  default_format_opts = {
    -- Allow formatting from LSP server if no dedicated formatter is available
    lsp_format = "fallback",
  },
  -- Map of filetype to formatters
  -- Make sure that necessary CLI tool is available
  formatters_by_ft = {
    lua = { "stylua" },
    cmake = { "gersemi" },
  },
})

vim.keymap.set("n", "<LEADER>cf", function()
  require("conform").format()
end, { desc = "format" })
