-- CMake language server. The root is the git repository, so include()d files
-- anywhere in the project resolve; outside a repository the nearest
-- directory with a CMakeLists.txt; with neither the server runs on the
-- single file and scans nothing else.

return {
  cmd = { "neocmakelsp", "stdio", },
  filetypes = { "cmake", },
  root_markers = { ".git", "CMakeLists.txt", },
  on_init = function(client)
    -- CMake is formatted by gersemi (<leader>lf), never by this server.
    -- Done before attach, so Neovim also leaves 'formatexpr' unset and gq
    -- keeps plain text formatting.
    local caps = client.server_capabilities
    if caps then
      caps.documentFormattingProvider = false
      caps.documentRangeFormattingProvider = false
      caps.documentOnTypeFormattingProvider = nil
    end
  end,
}
