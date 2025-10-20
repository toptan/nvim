return {
  "nvim-mini/mini.nvim",
  version = false,
  config = function()
    require("config.mini.clue")
    require("config.mini.completion")
    require("config.mini.diff")
    require("config.mini.extra")
    require("config.mini.base16")
    require("config.mini.files")
    require("config.mini.icons")
    require("config.mini.notify")
    require("config.mini.pick")
    require("config.mini.starter")
    require("config.mini.statusline")
  end,
}
