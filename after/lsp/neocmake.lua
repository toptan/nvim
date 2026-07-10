---@type vim.lsp.Config
return {
  cmd = { "neocmakelsp", "stdio" },
  filetypes = { "cmake" },
  root_markers = {
    "CMakePresets.json",
    "CMakeLists.txt",
    "build",
    "cmake",
    ".git",
  },
  init_options = {
    format = { enable = true },
    lint = { enable = true },
    scan_cmake_in_package = true,
    semantic_token = false,
  },
}
