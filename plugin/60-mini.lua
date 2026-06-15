vim.pack.add({ "https://github.com/nvim-mini/mini.nvim" })

local gr = vim.api.nvim_create_augroup("custom-config", {})
local new_autocmd = function(event, pattern, callback, desc)
  local opts =
  { group = gr, pattern = pattern, callback = callback, desc = desc }
  vim.api.nvim_create_autocmd(event, opts)
end

local misc = require("mini.misc")
local now = function(f)
  misc.safely("now", f)
end
local later = function(f)
  misc.safely("later", f)
end
local now_if_args = vim.fn.argc(-1) > 0 and now or later

-- Completion --
now_if_args(function()
  -- Customize post-processing of LSP responses for a better user experience.
  -- Don't show 'Text' suggestions (usually noisy) and show snippets last.
  local process_items_opts = { kind_priority = { Text = -1, Snippet = 99 } }
  local process_items = function(items, base)
    return MiniCompletion.default_process_items(items, base, process_items_opts)
  end
  require("mini.completion").setup({
    lsp_completion = {
      -- Without this config autocompletion is set up through `:h 'completefunc'`.
      -- Although not needed, setting up through `:h 'omnifunc'` is cleaner
      -- (sets up only when needed) and makes it possible to use `<C-u>`.
      source_func = "omnifunc",
      auto_setup = false,
      process_items = process_items,
    },
  })

  -- Set 'omnifunc' for LSP completion only when needed.
  local on_attach = function(ev)
    vim.bo[ev.buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"
  end
  new_autocmd("LspAttach", nil, on_attach, "Set 'omnifunc'")

  -- Advertise to servers that Neovim now supports certain set of completion and
  -- signature features through 'mini.completion'.
  vim.lsp.config("*", { capabilities = MiniCompletion.get_lsp_capabilities() })
end)
