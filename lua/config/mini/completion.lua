local kind_priority = { Text = -1, Snippet = 99 }
local opts = { filtersort = "fuzzy", kind_priority = kind_priority }
local process_items = function(items, base)
  return MiniCompletion.default_process_items(items, base, opts)
end

require("mini.completion").setup({
  lsp_completion = { process_items = process_items },
})
