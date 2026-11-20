-- Automatic insert-mode completion in buffers with a language server (server
-- suggestions first, then buffer words) and IDE-style keys: <Tab>/<S-Tab> to
-- move, <CR> to accept, <C-Space> to trigger. Built on 'autocomplete' and
-- vim.lsp.completion; no plugin.

local M = {}

local group = vim.api.nvim_create_augroup("config_completion", {
  clear = true,
})

local method = "textDocument/completion"

-- Looked up on use: touching vim.lsp at startup would load it.
local function trigger_kind()
  return vim.lsp.protocol.CompletionTriggerKind
end

local function pum_visible()
  return vim.fn.pumvisible() == 1
end

local function line_to_cursor()
  return vim.api.nvim_get_current_line():sub(1, vim.fn.col(".") - 1)
end

local function completion_clients(buf)
  return vim.lsp.get_clients({ bufnr = buf, method = method, })
end

-- Fuzzy scores of item words against the word being typed. Dropped when that
-- word changes, so one sort computes each score once.
local cache = { word = nil, scores = {}, }

local function score(word)
  local typed = vim.fn.matchstr(line_to_cursor(), [[\k*$]])
  if typed ~= cache.word then
    cache = { word = typed, scores = {}, }
  end
  local s = cache.scores[word]
  if s == nil then
    if typed == "" then
      s = 0
    else
      s = vim.fn.matchfuzzypos({ word, }, typed)[3][1] or -1
    end
    cache.scores[word] = s
  end
  return s
end

local function lsp_item(item)
  return vim.tbl_get(item, "user_data", "nvim", "lsp", "completion_item")
end

-- Server items before buffer words; within each group the best fuzzy match
-- first, then the server's sortText, then the word. Server items sort first
-- so a buffer word with the same text is dropped as a duplicate.
local function compare(a, b)
  local la, lb = lsp_item(a), lsp_item(b)
  if (la ~= nil) ~= (lb ~= nil) then
    return la ~= nil
  end
  local sa, sb = score(a.word), score(b.word)
  if sa ~= sb then
    return sa > sb
  end
  local ka = la and (la.sortText or la.label) or a.word
  local kb = lb and (lb.sortText or lb.label) or b.word
  if ka ~= kb then
    return ka < kb
  end
  return a.word < b.word
end

local function after_word_character()
  return vim.fn.match(line_to_cursor():sub(-1), [[\k]]) == 0
end

-- The trigger character of a server attached to buf that the text before the
-- cursor ends with, or nil. Whitespace triggers (lua_ls has " ", "\t" and
-- "\n") are ignored: a space or new line opens no menu.
local function trigger_character(buf)
  local before = line_to_cursor()
  for _, client in ipairs(completion_clients(buf)) do
    local chars = vim.tbl_get(client.server_capabilities, "completionProvider",
      "triggerCharacters") or {}
    for _, char in ipairs(chars) do
      if char:match("^%S+$") and before:sub(-#char) == char then
        return char
      end
    end
  end
  return nil
end

-- 'completefunc' source for 'autocomplete': server suggestions for the word
-- being typed. 'autocomplete' also calls it on entering insert mode, after
-- automatic indentation and after punctuation; those ask nothing, so no
-- menu opens on a blank line. Trigger characters are handled below.
function M.source(findstart, base)
  if findstart == 1 and not after_word_character() then
    return -3
  end
  return vim.lsp.omnifunc(findstart, base)
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method(method, args.buf) then
      return
    end
    vim.lsp.completion.enable(true, client.id, args.buf, { cmp = compare, })
    vim.bo[args.buf].autocomplete = true
    vim.bo[args.buf].complete = "F,.,w,b,u"
    vim.bo[args.buf].completefunc = "v:lua.require'config.completion'.source"
    -- 'fuzzy' would re-rank the menu on every key, mixing buffer words in
    -- between server items; keep the order of compare().
    vim.api.nvim_buf_call(args.buf, function()
      vim.opt_local.completeopt:append("nosort")
    end)
  end,
})

-- Whether the open menu already holds the server's answer.
local function menu_has_server_items()
  for _, item in ipairs(vim.fn.complete_info({ "items", }).items) do
    if lsp_item(item) then
      return true
    end
  end
  return false
end

-- 'autocomplete' asks the sources once and then only filters while the menu
-- is open. Servers may return a partial list (clangd stops at 100 items), so
-- ask again as the word grows; vim.lsp.completion skips the request unless
-- the previous answer was marked incomplete. Not before the first answer
-- arrived: the new request would cancel it.
vim.api.nvim_create_autocmd("TextChangedP", {
  group = group,
  callback = function(args)
    if not vim.bo[args.buf].autocomplete
      or not after_word_character()
      or not menu_has_server_items() then
      return
    end
    vim.lsp.completion.get({
      ctx = { triggerKind = trigger_kind().TriggerForIncompleteCompletions, },
    })
  end,
})

-- After a trigger character ask the server like vim.lsp.completion's own
-- autotrigger does, naming the character, so the server can tell "::" from
-- a label's ":" and "->" from ">". Deferred until automatic indentation is
-- done: cindent moves "std:" as a label until the second ":", and a request
-- sent before that returns nothing.
vim.api.nvim_create_autocmd("TextChangedI", {
  group = group,
  callback = function(args)
    if not vim.bo[args.buf].autocomplete then
      return
    end
    local char = trigger_character(args.buf)
    if not char then
      return
    end
    local tick = vim.b[args.buf].changedtick
    vim.defer_fn(function()
      if vim.api.nvim_get_current_buf() ~= args.buf
        or vim.b[args.buf].changedtick ~= tick
        or vim.fn.mode() ~= "i"
        or pum_visible() then
        return
      end
      vim.lsp.completion.get({
        ctx = {
          triggerKind = trigger_kind().TriggerCharacter,
          triggerCharacter = char,
        },
      })
    end, 25)
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  group = group,
  callback = function(args)
    for _, client in ipairs(completion_clients(args.buf)) do
      if client.id ~= args.data.client_id then
        return
      end
    end
    vim.api.nvim_buf_call(args.buf, function()
      vim.cmd("setlocal autocomplete< complete< completefunc< completeopt<")
    end)
  end,
})

-- <Down>/<Up> select without inserting (:h popupmenu-keys). <C-n>/<C-p>
-- cannot be remapped while the menu is open, so they keep their preview.
-- With the menu closed these reproduce Neovim's default snippet jumps.
local function tab(key, menu_key, direction)
  return function()
    if pum_visible() then
      return menu_key
    end
    if vim.snippet.active({ direction = direction, }) then
      return ("<Cmd>lua vim.snippet.jump(%d)<CR>"):format(direction)
    end
    return key
  end
end

vim.keymap.set("i", "<Tab>", tab("<Tab>", "<Down>", 1), {
  expr = true,
  desc = "Next completion item, snippet jump or Tab",
})
vim.keymap.set("i", "<S-Tab>", tab("<S-Tab>", "<Up>", -1), {
  expr = true,
  desc = "Previous completion item, snippet jump or S-Tab",
})

vim.keymap.set("i", "<CR>", function()
  if not pum_visible() then
    return "<CR>"
  end
  if vim.fn.complete_info({ "selected", }).selected ~= -1 then
    return "<C-y>"
  end
  return "<C-e><CR>"
end, { expr = true, desc = "Accept selected completion item or new line", })

-- With a word started, <C-n> runs the same sources as the automatic menu;
-- with nothing typed it would not ask the server, so ask it directly.
local function trigger()
  if pum_visible() or #completion_clients(0) == 0 then
    return ""
  end
  if vim.fn.matchstr(line_to_cursor(), [[\k*$]]) ~= "" then
    return "<C-n>"
  end
  vim.lsp.completion.get()
  return ""
end

-- Terminals usually send Ctrl+Space as <C-@>.
for _, lhs in ipairs({ "<C-Space>", "<C-@>", }) do
  vim.keymap.set("i", lhs, trigger, {
    expr = true,
    desc = "Trigger completion",
  })
end

return M
