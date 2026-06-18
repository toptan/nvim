local add = vim.pack.add

-- Ayu colorscheme
-- add({ "https://github.com/Shatur/neovim-ayu.git" })
-- vim.cmd.colorscheme("ayu")

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

vim.keymap.set("n", "<Leader>cf", function()
  require("conform").format()
end, { desc = "Format" })

-- Define hook to update tree-sitter parsers after plugin is updated
local ts_update = function()
  vim.cmd("TSUpdate")
end
Config.on_packchanged("nvim-treesitter", { "update" }, ts_update, ":TSUpdate")

add({
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
})

-- Define languages which will have parsers installed and auto enabled
-- After changing this, restart Neovim once to install necessary parsers. Wait
-- for the installation to finish before opening a file for added language(s).
local languages = {
  -- These are already pre-installed with Neovim. Used as an example.
  "asm",
  "c",
  "cmake",
  "cpp",
  "editorconfig",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "regex",
  "vim",
  "vimdoc",
  -- Add here more languages with which you want to use tree-sitter
  -- To see available languages:
  -- - Execute `:=require('nvim-treesitter').get_available()`
  -- - Visit 'SUPPORTED_LANGUAGES.md' file at
  --   https://github.com/nvim-treesitter/nvim-treesitter/blob/main
}
local isnt_installed = function(lang)
  return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
end
local to_install = vim.tbl_filter(isnt_installed, languages)
if #to_install > 0 then
  require("nvim-treesitter").install(to_install)
end

-- Enable tree-sitter after opening a file for a target language
local filetypes = {}
for _, lang in ipairs(languages) do
  for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
    table.insert(filetypes, ft)
  end
end
local ts_start = function(ev)
  vim.treesitter.start(ev.buf)
end
Config.new_autocmd("FileType", filetypes, ts_start, "Start tree-sitter")
