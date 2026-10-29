-- This file contains configuration of 'lua_ls' language server.
-- Source: https://github.com/LuaLS/lua-language-server
--
-- It is used by `:h vim.lsp.enable()` and `:h vim.lsp.config()`.
-- See `:h vim.lsp.Config` and `:h vim.lsp.ClientConfig` for all available fields.
--
-- This config is designed for Lua's activity around Neovim. It provides only
-- basic config and can be further improved.
local root_markers1 = {
    ".emmyrc.json",
    ".luarc.json",
    ".luarc.jsonc",
}
local root_markers2 = {
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
}

return {
    on_attach = function(client, buf_id)
        -- Reduce very long list of triggers for better 'mini.completion' experience
        client.server_capabilities.completionProvider.triggerCharacters = { ".", ":", "#", "(" }

        -- Use this function to define buffer-local mappings and behavior that depend
        -- on attached client or only makes sense if there is language server attached.
    end,
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = vim.list_extend(vim.list_extend(root_markers1, root_markers2), { ".git" }),
    -- LuaLS Structure of these settings comes from LuaLS, not Neovim
    settings = {
        Lua = {
            -- Define runtime properties. Use 'LuaJIT', as it is built into Neovim.
            runtime = { version = "LuaJIT", path = vim.split(package.path, ";") },
            workspace = {
                -- Do analyze code from submodules
                ignoreSubmodules = false,
                -- Add Neovim's methods for easier code writing
                library = { vim.env.VIMRUNTIME },
            },
        },
    },
}
