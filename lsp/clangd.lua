-- C-family language server. A directory with its own clangd setup
-- (.clangd, compile_commands.json, compile_flags.txt) is the root, otherwise
-- the git repository; with neither the server runs on the single file. The
-- root only scopes the client: clangd finds each file's compilation database
-- itself. It runs without flags, so its own database lookup, #include
-- insertion and .clang-format handling apply. Formatting is deliberately
-- kept: <leader>lf and gq format through clangd.

return {
  cmd = { "clangd", },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda", },
  root_markers = {
    { ".clangd", "compile_commands.json", "compile_flags.txt", },
    ".git",
  },
}
