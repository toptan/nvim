vim.lsp.enable({ "lua_ls" })

-- Diagnostic Config
-- See :help vim.diagnostic.Opts
vim.diagnostic.config({
  severity_sort = true,
  float = {
    border = "rounded",
    source = "if_many",
  },
  underline = {
    severity = vim.diagnostic.severity.ERROR,
  },
  virtual_text = {
    source = "if_many",
    spacing = 2,
    format = function(diagnostic)
      local diagnostic_message = {
        [vim.diagnostic.severity.ERROR] = diagnostic.message,
        [vim.diagnostic.severity.WARN] = diagnostic.message,
        [vim.diagnostic.severity.INFO] = diagnostic.message,
        [vim.diagnostic.severity.HINT] = diagnostic.message,
      }
      return diagnostic_message[diagnostic.severity]
    end,
  },
  virtual_lines = {
    source = "if_many",
    spacing = 2,
    format = function(diagnostic)
      local diagnostic_message = {
        [vim.diagnostic.severity.ERROR] = diagnostic.message,
        [vim.diagnostic.severity.WARN] = diagnostic.message,
        [vim.diagnostic.severity.INFO] = diagnostic.message,
        [vim.diagnostic.severity.HINT] = diagnostic.message,
      }
      return diagnostic_message[diagnostic.severity]
    end,
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    local buf = ev.buf

    -- Completion
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })
    end

    -- Inlay hints
    if client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = buf })
    end

    -- Folding
    if client:supports_method("textDocument/foldingRange") then
      local win = vim.api.nvim_get_current_win()
      vim.wo[win][0].foldmethod = "expr"
      vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
    end

    -- Document highlight (highlight references under cursor)
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
          vim.lsp.buf.format({ bufnr = buf, id = client.id })
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

    -- Inlay hints
    if client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = buf })
      vim.keymap.set("n", "\\h", function()
        vim.lsp.inlay_hint.enable(
          not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
          { bufnr = ev.buf }
        )
      end, { buffer = ev.buf, desc = "Toggle inlay hints" })
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
          vim.lsp.buf.format({ bufnr = buf, id = client.id })
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
