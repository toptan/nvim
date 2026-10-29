-- To minimize the time until first screen draw, modules are enabled in two steps:
-- - Step one enables everything that is needed for first draw with `now()`.
--   Sometimes needed only if Neovim is started as `nvim -- path/to/file`.
-- - Everything else is delayed until the first draw with `later()`.
local now         = Config.now
local now_if_args = Config.now_if_args
local later       = Config.later

now(function() vim.cmd.colorscheme("minischeme") end)

now(function()
    require("mini.basics").setup({
        -- Manage options in 'plugin/10_options.lua' for didactic purposes
        options = { basic = false, },
        mappings = {
            -- Create `<C-hjkl>` mappings for window navigation
            windows = true,
            -- Create `<M-hjkl>` mappings for navigation in Insert and Command modes
            move_with_alt = true,
        },
    })
end)

-- Icon provider. Usually no need to use manually. It is used by plugins like
-- 'mini.pick', 'mini.files', 'mini.statusline', and others.
now(function()
    -- Set up to not prefer extension-based icon for some extensions
    local ext3_blocklist = { scm = true, txt = true, yml = true, }
    local ext4_blocklist = { json = true, yaml = true, }
    require("mini.icons").setup({
        use_file_extension = function(ext, _)
            return not (ext3_blocklist[ext:sub(-3)] or ext4_blocklist[ext:sub(-4)])
        end,
    })

    -- Mock 'nvim-tree/nvim-web-devicons' for plugins without 'mini.icons' support.
    -- Not needed for 'mini.nvim' or MiniMax, but might be useful for others.
    later(MiniIcons.mock_nvim_web_devicons)

    -- Add LSP kind icons. Useful for 'mini.completion'.
    later(MiniIcons.tweak_lsp_kind)
end)

-- Notifications provider. Shows all kinds of notifications in the upper right
-- corner (by default). Example usage:
-- - `:h vim.notify()` - show notification (hides automatically)
-- - `<Leader>en` - show notification history
--
-- See also:
-- - `:h MiniNotify.config` for some of common configuration examples.
now(function() require("mini.notify").setup() end)

-- Session management. A thin wrapper around `:h mksession` that consistently
-- manages session files. Example usage:
-- - `<Leader>sn` - start new session
-- - `<Leader>sr` - read previously started session
-- - `<Leader>sd` - delete previously started session
now(function() require("mini.sessions").setup() end)

-- Start screen. This is what is shown when you open Neovim like `nvim`.
-- Example usage:
-- - Type prefix keys to limit available candidates
-- - Navigate down/up with `<C-n>` and `<C-p>`
-- - Press `<CR>` to select an entry
--
-- See also:
-- - `:h MiniStarter-example-config` - non-default config examples
-- - `:h MiniStarter-lifecycle` - how to work with Starter buffer
local function header_func()
    local hour = tonumber(vim.fn.strftime("%H"))
    -- [04:00, 12:00) - morning, [12:00, 20:00) - day, [20:00, 04:00) - evening
    local part_id = math.floor((hour + 4) / 8) + 1
    local day_part = ({ "evening", "morning", "afternoon", "evening", })
        [part_id]
    local username = vim.uv.os_get_passwd()["username"] or "USERNAME"

    return ("Good %s, %s!\n\nWhere there is a shell, there is a way."):format(
        day_part, username)
end

local function footer_func()
    return "The computer scientist's main challenge is not to\n"
        .. "get confused by the complexities of his own making.\n"
        .. "\n"
        .. "                              -- Edsger W. Dijkstra"
end

now(function()
    require("mini.starter").setup({
        header = header_func,
        footer = footer_func,
        query_updaters = "abcdefghijklmnopqrstuvwxyz0123456789_.",
    })
end)

-- Statuscolumn. Sets `:h 'statuscolumn'` for improved window's left column.
-- Example usage:
-- - Shows differently in active and inactive windows. By default, with separator
--   and dimmed respectively.
-- - Reorders main sections (line number, folds, and signs) for a more efficient
--   use of space.
-- - Shows extra indication for virtual and wrapped lines.
--
-- See also:
-- - `:h MiniStatuscolumn.config` - general overview of available configuration.
-- - `:h MiniStatuscolumn.gen_content.main()` - simplified content customization.
now(function() require("mini.statuscolumn").setup() end)

-- Statusline. Sets `:h 'statusline'` to show more info in a line below window.
-- Example usage:
-- - Left most section indicates current mode (text + highlighting).
-- - Second from left section shows "developer info": Git, diff, diagnostics, LSP.
-- - Center section shows the name of displayed buffer.
-- - Second to right section shows more buffer info.
-- - Right most section shows current cursor coordinates and search results.
--
-- See also:
-- - `:h MiniStatusline-example-content` - example of default content. Use it to
--   configure a custom statusline by setting `config.content.active` function.
now(function() require("mini.statusline").setup() end)

-- Completion and signature help. Implements async "two stage" autocompletion:
-- - Based on attached LSP servers that support completion.
-- - Fallback (based on built-in keyword completion) if there is no LSP candidates.
--
-- Example usage in Insert mode with attached LSP:
-- - Start typing text that should be recognized by LSP (like variable name).
-- - After 100ms a popup menu with candidates appears.
-- - Press `<Tab>` / `<S-Tab>` to navigate down/up the list. These are set up
--   in 'mini.keymap'. You can also use `<C-n>` / `<C-p>`.
-- - During navigation there is an info window to the right showing extra info
--   that the LSP server can provide about the candidate. It appears after the
--   candidate stays selected for 100ms. Use `<C-f>` / `<C-b>` to scroll it.
-- - Navigating to an entry also changes buffer text. If you are happy with it,
--   keep typing after it. To discard completion completely, press `<C-e>`.
-- - After pressing special trigger(s), usually `(`, a window appears that shows
--   the signature of the current function/method. It gets updated as you type
--   showing the currently active parameter.
--
-- Example usage in Insert mode without an attached LSP or in places not
-- supported by the LSP (like comments):
-- - Start typing a word that is present in current or opened buffers.
-- - After 100ms popup menu with candidates appears.
-- - Navigate with `<Tab>` / `<S-Tab>` or `<C-n>` / `<C-p>`. This also updates
--   buffer text. If happy with choice, keep typing. Stop with `<C-e>`.
--
-- It also works with snippet candidates provided by LSP server. Best experience
-- when paired with 'mini.snippets' (which is set up in this file).
now_if_args(function()
    -- Customize post-processing of LSP responses for a better user experience.
    -- Don't show 'Text' suggestions (usually noisy) and show snippets last.
    local process_items_opts = { kind_priority = { Text = -1, Snippet = 99, }, }
    local process_items = function(items, base)
        return MiniCompletion.default_process_items(items, base,
                                                    process_items_opts)
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
    Config.new_autocmd("LspAttach", nil, on_attach, "Set 'omnifunc'")

    -- Advertise to servers that Neovim now supports certain set of completion and
    -- signature features through 'mini.completion'.
    vim.lsp.config("*", { capabilities = MiniCompletion.get_lsp_capabilities(), })
end)

-- Show next key clues in a bottom right window. Requires explicit opt-in for
-- keys that act as clue trigger. Example usage:
-- - Press `<Leader>` and wait for 1 second. A window with information about
--   next available keys should appear.
-- - Press one of the listed keys. Window updates immediately to show information
--   about new next available keys. You can press `<BS>` to go back in key sequence.
-- - Press keys until they resolve into some mapping.
--
-- Note: it is designed to work in buffers for normal files. It doesn't work in
-- special buffers (like for 'mini.starter' or 'mini.files') to not conflict
-- with its local mappings.
--
-- See also:
-- - `:h MiniClue-examples` - examples of common setups
-- - `:h MiniClue.ensure_buf_triggers()` - use it to enable triggers in buffer
-- - `:h MiniClue.set_mapping_desc()` - change mapping description not from config
later(function()
    local miniclue = require("mini.clue")
    -- stylua: ignore
    miniclue.setup({
        -- Define which clues to show. By default shows only clues for custom mappings
        -- (uses `desc` field from the mapping; takes precedence over custom clue).
        clues = {
            -- This is defined in 'plugin/20_keymaps.lua' with Leader group descriptions
            Config.leader_group_clues,
            miniclue.gen_clues.builtin_completion(),
            miniclue.gen_clues.g(),
            miniclue.gen_clues.marks(),
            miniclue.gen_clues.registers(),
            miniclue.gen_clues.square_brackets(),
            -- This creates a submode for window resize mappings. Try the following:
            -- - Press `<C-w>s` to make a window split.
            -- - Press `<C-w>+` to increase height. Clue window still shows clues as if
            --   `<C-w>` is pressed again. Keep pressing just `+` to increase height.
            --   Try pressing `-` to decrease height.
            -- - Stop submode either by `<Esc>` or by any key that is not in submode.
            miniclue.gen_clues.windows({ submode_resize = true, }),
            miniclue.gen_clues.z(),
        },
        -- Explicitly opt-in for set of common keys to trigger clue window
        triggers = {
            { mode = { "n", "x", }, keys = "<Leader>", }, -- Leader triggers
            { mode = "n",           keys = "\\", },       -- mini.basics
            { mode = { "n", "x", }, keys = "[", },        -- mini.bracketed
            { mode = { "n", "x", }, keys = "]", },
            { mode = "i",           keys = "<C-x>", },    -- Built-in completion
            { mode = { "n", "x", }, keys = "g", },        -- `g` key
            { mode = { "n", "x", }, keys = "'", },        -- Marks
            { mode = { "n", "x", }, keys = "`", },
            { mode = { "n", "x", }, keys = '"', },        -- Registers
            { mode = { "i", "c", }, keys = "<C-r>", },
            { mode = "n",           keys = "<C-w>", },    -- Window commands
            { mode = { "n", "x", }, keys = "s", },        -- `s` key (mini.surround, etc.)
            { mode = { "n", "x", }, keys = "z", },        -- `z` key
        },
    })
end)

-- Visualize and work with indent scope. It visualizes indent scope "at cursor"
-- with animated vertical line. Provides relevant motions and textobjects.
-- Example usage:
-- - `cii` - *c*hange *i*nside *i*ndent scope
-- - `Vaiai` - *V*isually select *a*round *i*ndent scope and then again
--   reselect *a*round new *i*indent scope
-- - `[i` / `]i` - navigate to scope's top / bottom
--
-- See also:
-- - `:h MiniIndentscope.gen_animation` - available animation rules
later(function() require("mini.indentscope").setup() end)

-- Customizable user input. Improves how Neovim and plugins ask for input.
-- By default shows a floating window with the input prompt as title. Window
-- position depends on the input scope: at cursor, window or editor bottom left.
--
-- When asked for input:
-- - Type it. Note: this is not a regular Insert mode, but rather a customizable
--   and comprehensive Command-line mode emulation (it allows returning a value).
-- - Press `<Tab>` to show completion, `<C-p>` - previous history entry.
-- - Press `<CR>` to accept or `<Esc>` to cancel.
--
-- Example usage (usually works together with other plugins and modules):
-- - `saiwf` and type a function name to wrap a word with 'mini.surround'
-- - `<Leader>lr` and type a new value to use with LSP rename
-- - `<Leader>fg` + `<C-o>` and type a custom filter glob for `grep_live` picker
-- - `:h vim.ui.input()` - implemented with 'mini.input'.
--   Like after typing `<Leader>sn` to create a session asks for its name.
--
-- See also:
-- - `:h MiniInput.default_key()` - default special keys available when typing
-- - `:h MiniInput-examples` - general customization examples
-- - `:h MiniInput.gen_view` - bundled view customizations (adjust how floating
--   window is shown or use statusline/tabline/winbar/virtual text)
-- - `:h MiniInput-lifecycle` - details about how a custom mode emulation works
later(function() require("mini.input").setup() end)

