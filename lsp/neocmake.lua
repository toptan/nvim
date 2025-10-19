return {
  cmd = { "neocmakelsp", "--stdio" },
  filetypes = { "cmake" },
  single_file_support = true, -- suggested
  init_options = {
    format = {
      enable = false,
    },
    lint = {
      enable = true,
    },
    scan_cmake_in_package = true, -- default is true
    semantic_token = false,
  },
  capabilities = require("mini.completion").get_lsp_capabilities(),
}
