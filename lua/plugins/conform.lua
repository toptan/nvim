return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      cmake = { "gersemi" },
      toml = { "pyproject-fmt" },
    },
  },
  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_format = "fallback",
  },
  keys = {
    {
      "<Leader>cf",
      function()
        require("conform").format({
          lsp_format = "fallback",
        })
      end,
      desc = "[F]ormat",
    },
  },
}
