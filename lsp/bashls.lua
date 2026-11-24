-- Shell script language server. The root is the git repository, so
-- go-to-definition follows source'd files anywhere in the project; outside a
-- repository the server runs on the single file and scans nothing else.
-- No settings: ShellCheck (diagnostics) and shfmt (formatting) are found on
-- PATH, and shfmt takes its indentation from 'shiftwidth'/'expandtab', i.e.
-- from .editorconfig or the config's defaults.

return {
  cmd = { "bash-language-server", "start", },
  filetypes = { "bash", "sh", },
  root_markers = { ".git", },
  on_init = function(client)
    -- The server offers formatting even without shfmt and then silently
    -- returns nothing. Without shfmt, drop the capability so <leader>lf says
    -- that the buffer cannot be formatted.
    local caps = client.server_capabilities
    if caps and vim.fn.executable("shfmt") == 0 then
      caps.documentFormattingProvider = false
    end
  end,
}
