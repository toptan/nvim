vim.lsp.enable({ "lua_ls" })

-- Diagnostic Config
-- See :help vim.diagnostic.Opts
local function diagnostic_format(diagnostic)
  local diagnostic_message = {
    [vim.diagnostic.severity.ERROR] = diagnostic.message,
    [vim.diagnostic.severity.WARN] = diagnostic.message,
    [vim.diagnostic.severity.INFO] = diagnostic.message,
    [vim.diagnostic.severity.HINT] = diagnostic.message,
  }
  return diagnostic_message[diagnostic.severity]
end

-- Diagnostic display modes, toggled with <Leader>tv
local virtual_text = {
  source = "if_many",
  spacing = 2,
  format = diagnostic_format,
}
local virtual_lines = {
  source = "if_many",
  spacing = 2,
  format = diagnostic_format,
}

vim.diagnostic.config({
  severity_sort = true,
  float = {
    border = "rounded",
    source = "if_many",
  },
  underline = {
    severity = vim.diagnostic.severity.ERROR,
  },
  -- virtual_text on by default; virtual_lines off (toggle with <Leader>tv)
  virtual_text = virtual_text,
  virtual_lines = false,
})

-- Toggle between virtual_text and virtual_lines diagnostic display
vim.keymap.set("n", "<Leader>tv", function()
  if vim.diagnostic.config().virtual_lines then
    vim.diagnostic.config({ virtual_text = virtual_text, virtual_lines = false })
  else
    vim.diagnostic.config({
      virtual_text = false,
      virtual_lines = virtual_lines,
    })
  end
end, { desc = "Virtual text/lines" })

-- Toggle diagnostics on/off
vim.keymap.set("n", "<Leader>td", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Diagnostics" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    local buf = ev.buf

    -- Completion via mini.completion
    if client:supports_method("textDocument/completion") then
      vim.bo[buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"
    end

    -- Inlay hints (off by default, toggle with <Leader>th)
    if client:supports_method("textDocument/inlayHint") then
      vim.keymap.set("n", "<Leader>th", function()
        vim.lsp.inlay_hint.enable(
          not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
          { bufnr = ev.buf }
        )
      end, { buffer = ev.buf, desc = "Inlay hints" })
    end

    -- Folding
    if client:supports_method("textDocument/foldingRange") then
      local win = vim.api.nvim_get_current_win()
      vim.wo[win][0].foldmethod = "expr"
      vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
    end

    -- Document highlight
    if client:supports_method("textDocument/documentHighlight") then
      local highlight_group =
        vim.api.nvim_create_augroup("LspHighlight_" .. buf, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = highlight_group,
        buffer = buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = highlight_group,
        buffer = buf,
        callback = vim.lsp.buf.clear_references,
      })
    end

    -- Format on save
    if client:supports_method("textDocument/formatting") then
      local format_group =
        vim.api.nvim_create_augroup("LspFormat_" .. buf, { clear = true })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        buffer = buf,
        callback = function()
          require("conform").format()
        end,
      })
    end
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  callback = function(ev)
    local buf = ev.buf
    pcall(vim.api.nvim_del_augroup_by_name, "LspHighlight_" .. buf)
    pcall(vim.api.nvim_del_augroup_by_name, "LspFormat_" .. buf)
    vim.lsp.buf.clear_references()
  end,
})
