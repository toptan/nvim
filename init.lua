-- Options must load first: they set the leader keys and provider flags.
require("config.options")
-- Before any module that notifies, so every notification reaches mini.notify.
require("config.notifications")
require("config.colorscheme")
require("config.search")
require("config.keymaps")
require("config.autocmds")
require("config.diagnostics")
require("config.lsp")
require("config.completion")
