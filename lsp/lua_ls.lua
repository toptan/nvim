-- Lua language server. Under a root without its own .luarc.json(c), the
-- server is taught the Neovim runtime, this config's modules and every
-- plugin installed with vim.pack.

-- Library roots: $VIMRUNTIME and each installed plugin. Evaluated on every
-- server start, so plugin changes are picked up after a restart.
local function library()
  local paths = { vim.env.VIMRUNTIME, }
  -- vim.pack.get() creates the plugin directory when it is missing, which
  -- :checkhealth then reports; without the directory there are no plugins.
  local pack_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack",
    "core", "opt")
  if not vim.uv.fs_stat(pack_dir) then
    return paths
  end
  local ok, plugins = pcall(vim.pack.get, nil, { info = false, })
  for _, plugin in ipairs(ok and plugins or {}) do
    paths[#paths + 1] = plugin.path
  end
  return paths
end

return {
  cmd = { "lua-language-server", },
  filetypes = { "lua", },
  root_markers = { { ".luarc.json", ".luarc.jsonc", }, ".git", },
  settings = { Lua = {}, },
  on_init = function(client)
    -- A project's own settings win: inject nothing.
    local folder = client.workspace_folders and client.workspace_folders[1]
    if folder then
      local root = folder.name
      if vim.uv.fs_stat(root .. "/.luarc.json")
          or vim.uv.fs_stat(root .. "/.luarc.jsonc") then
        return
      end
    end
    client.config.settings.Lua = vim.tbl_deep_extend(
      "force",
      client.config.settings.Lua or {},
      {
        runtime = {
          version = "LuaJIT",
          path = { "lua/?.lua", "lua/?/init.lua", },
        },
        workspace = {
          checkThirdParty = false,
          library = library(),
        },
      }
    )
    client:notify("workspace/didChangeConfiguration", {
      settings = client.config.settings,
    })
  end,
}
