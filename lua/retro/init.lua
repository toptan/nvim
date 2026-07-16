-- Shared implementation for the "retro" and "retroplus" colorschemes.
--
-- Both start from the built-in "retrobox" colorscheme and add the modern
-- highlight groups it lacks (Tree-sitter @*, LSP/diagnostics, semantic tokens,
-- floating windows, mini.nvim). They differ only in how the Tree-sitter
-- captures are colored:
--
--   * retroplus -- follows catppuccin's color-assignment logic
--                  (https://github.com/catppuccin/nvim): each group maps to a
--                  named palette role (Keyword -> mauve, @property -> lavender,
--                  ...). We keep those assignments but back the roles with
--                  retrobox/gruvbox colors. Richer, more colorful.
--
--   * retro     -- keeps retrobox's original hues by linking the captures to the
--                  classic base groups (@keyword -> Keyword (red), @type -> Type
--                  (yellow), @function -> Function (green), ...). Looks like
--                  plain retrobox, just with the extra UI groups defined.
--
-- Pure Lua. Respects &background (dark/light); reloaded automatically when it
-- changes.

local M = {}

-- Palettes, keyed by base colorscheme then background. The role names are
-- catppuccin's; the colors come from each base theme. Roles in the same hue
-- family may share a value when a base theme has fewer hues than catppuccin --
-- that is faithful to the base theme's look.
local palettes = {}

palettes.retrobox = {
  dark = {
    rosewater = "#fbf1c7",
    flamingo = "#d5c4a1",
    pink = "#d3869b",
    mauve = "#d3869b",
    red = "#fb5944",
    maroon = "#cc241d",
    peach = "#fe8019",
    yellow = "#fabd2f",
    green = "#b8bb26",
    teal = "#8ec07c",
    sky = "#8ec07c",
    sapphire = "#458588",
    blue = "#83a598",
    lavender = "#b16286",
    text = "#ebdbb2",
    subtext1 = "#d5c4a1",
    subtext0 = "#bdae93",
    overlay2 = "#a89984",
    overlay1 = "#928374",
    overlay0 = "#7c6f64",
    surface2 = "#665c54",
    surface1 = "#504945",
    surface0 = "#3c3836",
    base = "#1c1c1c",
    mantle = "#181818",
    crust = "#121212",
    dim = "#161616",
  },
  light = {
    rosewater = "#282828",
    flamingo = "#665c54",
    pink = "#8f3f71",
    mauve = "#8f3f71",
    red = "#9d0006",
    maroon = "#cc241d",
    peach = "#af3a03",
    yellow = "#b57614",
    green = "#79740e",
    teal = "#427b58",
    sky = "#427b58",
    sapphire = "#458588",
    blue = "#076678",
    lavender = "#b16286",
    text = "#3c3836",
    subtext1 = "#504945",
    subtext0 = "#665c54",
    overlay2 = "#7c6f64",
    overlay1 = "#928374",
    overlay0 = "#a89984",
    surface2 = "#bdae93",
    surface1 = "#d5c4a1",
    surface0 = "#ebdbb2",
    base = "#fbf1c7",
    mantle = "#f2e5bc",
    crust = "#ebdbb2",
    dim = "#f2e5bc",
  },
}

-- default: Neovim's built-in theme. Only six hues (NvimDark*/NvimLight*), so
-- several catppuccin roles collapse onto the nearest one.
palettes.default = {
  dark = {
    rosewater = "#eef1f8",
    flamingo = "#e0e2ea",
    pink = "#ffcaff",
    mauve = "#ffcaff",
    red = "#ffc0b9",
    maroon = "#ffc0b9",
    peach = "#fce094",
    yellow = "#fce094",
    green = "#b3f6c0",
    teal = "#8cf8f7",
    sky = "#8cf8f7",
    sapphire = "#8cf8f7",
    blue = "#a6dbff",
    lavender = "#a6dbff",
    text = "#e0e2ea",
    subtext1 = "#c4c6cd",
    subtext0 = "#9b9ea4",
    overlay2 = "#9b9ea4",
    overlay1 = "#9b9ea4",
    overlay0 = "#4f5258",
    surface2 = "#4f5258",
    surface1 = "#4f5258",
    surface0 = "#2c2e33",
    base = "#14161b",
    mantle = "#0e0f13",
    crust = "#07080d",
    dim = "#0e0f13",
  },
  light = {
    rosewater = "#14161b",
    flamingo = "#2c2e33",
    pink = "#470045",
    mauve = "#470045",
    red = "#590008",
    maroon = "#590008",
    peach = "#6b5300",
    yellow = "#6b5300",
    green = "#005523",
    teal = "#007373",
    sky = "#007373",
    sapphire = "#007373",
    blue = "#004c73",
    lavender = "#004c73",
    text = "#14161b",
    subtext1 = "#2c2e33",
    subtext0 = "#4f5258",
    overlay2 = "#4f5258",
    overlay1 = "#9b9ea4",
    overlay0 = "#9b9ea4",
    surface2 = "#9b9ea4",
    surface1 = "#c4c6cd",
    surface0 = "#c4c6cd",
    base = "#e0e2ea",
    mantle = "#eef1f8",
    crust = "#d4d7df",
    dim = "#eef1f8",
  },
}

-- habamax: a dark-only theme (it ignores 'background'), so both keys share the
-- same muted palette.
local habamax = {
  rosewater = "#dadada",
  flamingo = "#d7af87",
  pink = "#af87af",
  mauve = "#af87af",
  red = "#d75f87",
  maroon = "#d7875f",
  peach = "#d75f87",
  yellow = "#d7af5f",
  green = "#5faf5f",
  teal = "#5f8787",
  sky = "#87afaf",
  sapphire = "#5f87af",
  blue = "#5f87af",
  lavender = "#8787af",
  text = "#c7c7c7",
  subtext1 = "#b2b2b2",
  subtext0 = "#9e9e9e",
  overlay2 = "#949494",
  overlay1 = "#767676",
  overlay0 = "#585858",
  surface2 = "#585858",
  surface1 = "#3a3a3a",
  surface0 = "#303030",
  base = "#1c1c1c",
  mantle = "#161616",
  crust = "#121212",
  dim = "#161616",
}
palettes.habamax = { dark = habamax, light = habamax }

-- lunaperche.
palettes.lunaperche = {
  dark = {
    rosewater = "#ffffff",
    flamingo = "#ffd7af",
    pink = "#ff87ff",
    mauve = "#ff87ff",
    red = "#ff5f5f",
    maroon = "#ff8787",
    peach = "#ffaf5f",
    yellow = "#ffd787",
    green = "#5fd75f",
    teal = "#5fafaf",
    sky = "#5fd7d7",
    sapphire = "#87afff",
    blue = "#5fafff",
    lavender = "#d7afff",
    text = "#c6c6c6",
    subtext1 = "#bcbcbc",
    subtext0 = "#9e9e9e",
    overlay2 = "#949494",
    overlay1 = "#767676",
    overlay0 = "#585858",
    surface2 = "#4e4e4e",
    surface1 = "#303030",
    surface0 = "#262626",
    base = "#000000",
    mantle = "#0a0a0a",
    crust = "#121212",
    dim = "#0a0a0a",
  },
  light = {
    rosewater = "#000000",
    flamingo = "#5f5f5f",
    pink = "#af00af",
    mauve = "#af00af",
    red = "#d70000",
    maroon = "#af0000",
    peach = "#af5f00",
    yellow = "#af8700",
    green = "#008700",
    teal = "#008787",
    sky = "#005f5f",
    sapphire = "#005fd7",
    blue = "#005fd7",
    lavender = "#8700af",
    text = "#000000",
    subtext1 = "#1c1c1c",
    subtext0 = "#303030",
    overlay2 = "#585858",
    overlay1 = "#767676",
    overlay0 = "#9e9e9e",
    surface2 = "#c6c6c6",
    surface1 = "#e4e4e4",
    surface0 = "#eeeeee",
    base = "#ffffff",
    mantle = "#f4f4f4",
    crust = "#e4e4e4",
    dim = "#f4f4f4",
  },
}

-- Color utilities, ported from catppuccin (lua/catppuccin/utils/colors.lua).
local function hex_to_rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

-- alpha 0 -> bg, 1 -> fg
local function blend(fg, bg, alpha)
  local fr, fgc, fb = hex_to_rgb(fg)
  local br, bgc, bb = hex_to_rgb(bg)
  local function ch(f, b)
    return math.floor(math.min(math.max(0, alpha * f + (1 - alpha) * b), 255) + 0.5)
  end
  return string.format("#%02x%02x%02x", ch(fr, br), ch(fgc, bgc), ch(fb, bb))
end

-- Translate the { fg, bg, sp, style = {...}, link } schema into nvim_set_hl's
-- option table and apply it.
local function apply(groups)
  for name, spec in pairs(groups) do
    if spec.link then
      vim.api.nvim_set_hl(0, name, { link = spec.link })
    else
      local opts = { fg = spec.fg, bg = spec.bg, sp = spec.sp, blend = spec.blend }
      for _, s in ipairs(spec.style or {}) do
        opts[s] = true
      end
      vim.api.nvim_set_hl(0, name, opts)
    end
  end
end

-- Tree-sitter captures using catppuccin's role assignments (retroplus).
local function treesitter_plus(C)
  return {
    ["@variable"] = { fg = C.text },
    ["@variable.builtin"] = { fg = C.red },
    ["@variable.parameter"] = { fg = C.maroon },
    ["@variable.member"] = { fg = C.lavender },

    ["@constant"] = { link = "Constant" },
    ["@constant.builtin"] = { fg = C.peach },
    ["@constant.macro"] = { link = "Macro" },

    ["@module"] = { fg = C.yellow, style = { "italic" } },
    ["@label"] = { link = "Label" },

    ["@string"] = { link = "String" },
    ["@string.documentation"] = { fg = C.teal },
    ["@string.regexp"] = { fg = C.pink },
    ["@string.escape"] = { fg = C.pink },
    ["@string.special"] = { link = "Special" },
    ["@string.special.path"] = { link = "Special" },
    ["@string.special.symbol"] = { fg = C.flamingo },
    ["@string.special.url"] = { fg = C.blue, style = { "italic", "underline" } },
    ["@punctuation.delimiter.regex"] = { link = "@string.regexp" },

    ["@character"] = { link = "Character" },
    ["@character.special"] = { link = "SpecialChar" },

    ["@boolean"] = { link = "Boolean" },
    ["@number"] = { link = "Number" },
    ["@number.float"] = { link = "Float" },

    ["@type"] = { link = "Type" },
    ["@type.builtin"] = { fg = C.mauve },
    ["@type.definition"] = { link = "Type" },

    ["@attribute"] = { link = "Constant" },
    ["@property"] = { fg = C.lavender },

    ["@function"] = { link = "Function" },
    ["@function.builtin"] = { fg = C.peach },
    ["@function.call"] = { link = "Function" },
    ["@function.macro"] = { fg = C.pink },
    ["@function.method"] = { link = "Function" },
    ["@function.method.call"] = { link = "Function" },

    ["@constructor"] = { fg = C.yellow },
    ["@operator"] = { link = "Operator" },

    ["@keyword"] = { link = "Keyword" },
    ["@keyword.modifier"] = { link = "Keyword" },
    ["@keyword.type"] = { link = "Keyword" },
    ["@keyword.coroutine"] = { link = "Keyword" },
    ["@keyword.function"] = { fg = C.mauve },
    ["@keyword.operator"] = { fg = C.mauve },
    ["@keyword.import"] = { link = "Include" },
    ["@keyword.repeat"] = { link = "Repeat" },
    ["@keyword.return"] = { fg = C.mauve },
    ["@keyword.debug"] = { link = "Exception" },
    ["@keyword.exception"] = { link = "Exception" },
    ["@keyword.conditional"] = { link = "Conditional" },
    ["@keyword.conditional.ternary"] = { link = "Operator" },
    ["@keyword.directive"] = { link = "PreProc" },
    ["@keyword.directive.define"] = { link = "Define" },
    ["@keyword.export"] = { fg = C.mauve },

    ["@punctuation.delimiter"] = { link = "Delimiter" },
    ["@punctuation.bracket"] = { fg = C.overlay2 },
    ["@punctuation.special"] = { link = "Special" },

    ["@comment"] = { link = "Comment" },
    ["@comment.documentation"] = { link = "Comment" },
    ["@comment.error"] = { fg = C.base, bg = C.red },
    ["@comment.warning"] = { fg = C.base, bg = C.yellow },
    ["@comment.hint"] = { fg = C.base, bg = C.blue },
    ["@comment.todo"] = { fg = C.base, bg = C.flamingo },
    ["@comment.note"] = { fg = C.base, bg = C.rosewater },

    ["@markup"] = { fg = C.text },
    ["@markup.strong"] = { fg = C.red, style = { "bold" } },
    ["@markup.italic"] = { fg = C.red, style = { "italic" } },
    ["@markup.strikethrough"] = { fg = C.text, style = { "strikethrough" } },
    ["@markup.underline"] = { link = "Underlined" },
    ["@markup.heading"] = { fg = C.blue },
    ["@markup.heading.markdown"] = { style = { "bold" } },
    ["@markup.math"] = { fg = C.blue },
    ["@markup.quote"] = { fg = C.pink },
    ["@markup.environment"] = { fg = C.pink },
    ["@markup.environment.name"] = { fg = C.blue },
    ["@markup.link"] = { fg = C.lavender },
    ["@markup.link.label"] = { fg = C.lavender },
    ["@markup.link.url"] = { fg = C.blue, style = { "italic", "underline" } },
    ["@markup.raw"] = { fg = C.green },
    ["@markup.list"] = { fg = C.teal },
    ["@markup.list.checked"] = { fg = C.green },
    ["@markup.list.unchecked"] = { fg = C.overlay1 },

    ["@diff.plus"] = { link = "diffAdded" },
    ["@diff.minus"] = { link = "diffRemoved" },
    ["@diff.delta"] = { link = "diffChanged" },

    ["@tag"] = { fg = C.blue },
    ["@tag.builtin"] = { fg = C.blue },
    ["@tag.attribute"] = { fg = C.yellow, style = { "italic" } },
    ["@tag.delimiter"] = { fg = C.teal },

    ["@error"] = { link = "Error" },

    -- Language specific
    ["@function.builtin.bash"] = { fg = C.red, style = { "italic" } },
    ["@variable.parameter.bash"] = { fg = C.green },

    ["@markup.heading.1.markdown"] = { link = "rainbow1" },
    ["@markup.heading.2.markdown"] = { link = "rainbow2" },
    ["@markup.heading.3.markdown"] = { link = "rainbow3" },
    ["@markup.heading.4.markdown"] = { link = "rainbow4" },
    ["@markup.heading.5.markdown"] = { link = "rainbow5" },
    ["@markup.heading.6.markdown"] = { link = "rainbow6" },

    ["@constant.java"] = { fg = C.teal },

    ["@property.css"] = { fg = C.blue },
    ["@property.scss"] = { fg = C.blue },
    ["@property.id.css"] = { fg = C.yellow },
    ["@property.class.css"] = { fg = C.yellow },
    ["@type.css"] = { fg = C.lavender },
    ["@type.tag.css"] = { fg = C.blue },
    ["@string.plain.css"] = { fg = C.text },
    ["@number.css"] = { fg = C.peach },
    ["@keyword.directive.css"] = { link = "Keyword" },

    ["@string.special.url.html"] = { fg = C.green },
    ["@markup.link.label.html"] = { fg = C.text },
    ["@character.special.html"] = { fg = C.red },

    ["@constructor.lua"] = { link = "@punctuation.bracket" },
    ["@constructor.python"] = { fg = C.sky },
    ["@label.yaml"] = { fg = C.yellow },
    ["@string.special.symbol.ruby"] = { fg = C.flamingo },
    ["@function.method.php"] = { link = "Function" },
    ["@function.method.call.php"] = { link = "Function" },
    ["@keyword.import.c"] = { fg = C.yellow },
    ["@keyword.import.cpp"] = { fg = C.yellow },
    ["@attribute.c_sharp"] = { fg = C.yellow },
    ["@comment.warning.gitcommit"] = { fg = C.yellow },
    ["@string.special.path.gitignore"] = { fg = C.text },

    gitcommitSummary = { fg = C.rosewater, style = { "italic" } },
    zshKSHFunction = { link = "Function" },
  }
end

-- Tree-sitter captures linked to retrobox's classic base groups, preserving its
-- original hues (retro).
local function treesitter_retro(C)
  return {
    -- Identifiers
    ["@variable"] = { fg = C.text },
    ["@variable.builtin"] = { link = "Keyword" }, -- self/this read like keywords (red)
    ["@variable.parameter"] = { fg = C.text },
    ["@variable.member"] = { link = "Identifier" }, -- fields -> blue

    ["@constant"] = { link = "Constant" },
    ["@constant.builtin"] = { link = "Constant" },
    ["@constant.macro"] = { link = "Macro" },

    ["@module"] = { link = "Type" },
    ["@label"] = { link = "Label" },

    ["@string"] = { link = "String" },
    ["@string.documentation"] = { link = "String" },
    ["@string.regexp"] = { link = "SpecialChar" },
    ["@string.escape"] = { link = "SpecialChar" },
    ["@string.special"] = { link = "Special" },
    ["@string.special.path"] = { link = "Special" },
    ["@string.special.symbol"] = { link = "Constant" },
    ["@string.special.url"] = { link = "Underlined" },

    ["@character"] = { link = "Character" },
    ["@character.special"] = { link = "SpecialChar" },

    ["@boolean"] = { link = "Boolean" },
    ["@number"] = { link = "Number" },
    ["@number.float"] = { link = "Float" },

    ["@type"] = { link = "Type" },
    ["@type.builtin"] = { link = "Type" },
    ["@type.definition"] = { link = "Type" },

    ["@attribute"] = { link = "PreProc" },
    ["@property"] = { link = "Identifier" },

    ["@function"] = { link = "Function" },
    ["@function.builtin"] = { link = "Function" },
    ["@function.call"] = { link = "Function" },
    ["@function.macro"] = { link = "Macro" },
    ["@function.method"] = { link = "Function" },
    ["@function.method.call"] = { link = "Function" },

    ["@constructor"] = { link = "Function" },
    ["@operator"] = { link = "Operator" },

    ["@keyword"] = { link = "Keyword" },
    ["@keyword.modifier"] = { link = "Keyword" },
    ["@keyword.type"] = { link = "Keyword" },
    ["@keyword.coroutine"] = { link = "Keyword" },
    ["@keyword.function"] = { link = "Keyword" },
    ["@keyword.operator"] = { link = "Operator" },
    ["@keyword.import"] = { link = "Include" },
    ["@keyword.repeat"] = { link = "Repeat" },
    ["@keyword.return"] = { link = "Keyword" },
    ["@keyword.debug"] = { link = "Debug" },
    ["@keyword.exception"] = { link = "Exception" },
    ["@keyword.conditional"] = { link = "Conditional" },
    ["@keyword.conditional.ternary"] = { link = "Operator" },
    ["@keyword.directive"] = { link = "PreProc" },
    ["@keyword.directive.define"] = { link = "Define" },
    ["@keyword.export"] = { link = "Keyword" },

    ["@punctuation.delimiter"] = { link = "Delimiter" },
    ["@punctuation.bracket"] = { fg = C.subtext1 },
    ["@punctuation.special"] = { link = "Special" },

    ["@comment"] = { link = "Comment" },
    ["@comment.documentation"] = { link = "Comment" },
    ["@comment.error"] = { fg = C.base, bg = C.red },
    ["@comment.warning"] = { fg = C.base, bg = C.yellow },
    ["@comment.hint"] = { fg = C.base, bg = C.teal },
    ["@comment.todo"] = { fg = C.base, bg = C.yellow },
    ["@comment.note"] = { fg = C.base, bg = C.blue },

    -- Markup
    ["@markup"] = { fg = C.text },
    ["@markup.strong"] = { fg = C.text, style = { "bold" } },
    ["@markup.italic"] = { fg = C.text, style = { "italic" } },
    ["@markup.strikethrough"] = { fg = C.text, style = { "strikethrough" } },
    ["@markup.underline"] = { link = "Underlined" },
    ["@markup.heading"] = { link = "Title" },
    ["@markup.heading.markdown"] = { style = { "bold" } },
    ["@markup.math"] = { link = "Special" },
    ["@markup.quote"] = { link = "Comment" },
    ["@markup.environment"] = { link = "Keyword" },
    ["@markup.environment.name"] = { link = "Type" },
    ["@markup.link"] = { link = "Underlined" },
    ["@markup.link.label"] = { link = "Identifier" },
    ["@markup.link.url"] = { link = "Underlined" },
    ["@markup.raw"] = { link = "String" },
    ["@markup.list"] = { link = "Special" },
    ["@markup.list.checked"] = { fg = C.green },
    ["@markup.list.unchecked"] = { fg = C.overlay1 },

    ["@markup.heading.1.markdown"] = { link = "rainbow1" },
    ["@markup.heading.2.markdown"] = { link = "rainbow2" },
    ["@markup.heading.3.markdown"] = { link = "rainbow3" },
    ["@markup.heading.4.markdown"] = { link = "rainbow4" },
    ["@markup.heading.5.markdown"] = { link = "rainbow5" },
    ["@markup.heading.6.markdown"] = { link = "rainbow6" },

    ["@diff.plus"] = { link = "diffAdded" },
    ["@diff.minus"] = { link = "diffRemoved" },
    ["@diff.delta"] = { link = "diffChanged" },

    ["@tag"] = { link = "Statement" },
    ["@tag.builtin"] = { link = "Statement" },
    ["@tag.attribute"] = { link = "Type" },
    ["@tag.delimiter"] = { link = "Delimiter" },

    ["@error"] = { link = "Error" },
  }
end

-- opts = {
--   name   -- name of this colorscheme (e.g. "defaultplus")
--   base   -- built-in colorscheme to load first (e.g. "default")
--   flavor -- "plus" (catppuccin-style captures) or "classic" (original hues)
-- }
-- The palette is looked up by `base`.
function M.load(opts)
  -- Load the base colorscheme. It clears highlights and defines every classic
  -- group for the current &background. We layer the missing groups on top and
  -- rename the scheme.
  vim.cmd("runtime colors/" .. opts.base .. ".vim")
  vim.g.colors_name = opts.name

  local dark = vim.o.background ~= "light"
  local C = vim.deepcopy(palettes[opts.base][dark and "dark" or "light"])
  C.none = "NONE"

  local function darken(hex, amount, bg)
    return blend(hex, bg or C.base, amount)
  end

  -- Editor: floating windows, separators, winbar, and a few UI extras retrobox
  -- leaves to defaults.
  local editor = {
    NormalFloat = { fg = C.text, bg = C.mantle },
    FloatBorder = { fg = C.blue, bg = C.mantle },
    FloatTitle = { fg = C.subtext0, bg = C.mantle },
    FloatShadow = { bg = C.overlay0, blend = 80 },
    WinSeparator = { fg = C.crust },
    MsgSeparator = { link = "WinSeparator" },
    WinBar = { fg = C.rosewater },
    WinBarNC = { link = "WinBar" },
    Whitespace = { fg = C.surface1 },
    Substitute = { bg = C.surface1, fg = C.pink },
    TermCursor = { fg = C.base, bg = C.rosewater },
    Dimmed = { fg = C.overlay1 },
  }

  -- Syntax extras: diffs, markup, rainbow, health, glyphs. retrobox already
  -- defines the core syntax groups, so those are left untouched.
  local syntax = {
    Bold = { style = { "bold" } },
    Italic = { style = { "italic" } },

    Added = { fg = C.green },
    Changed = { fg = C.blue },
    Removed = { fg = C.red },
    diffAdded = { fg = C.green },
    diffRemoved = { fg = C.red },
    diffChanged = { fg = C.blue },
    diffOldFile = { fg = C.yellow },
    diffNewFile = { fg = C.peach },
    diffFile = { fg = C.blue },
    diffLine = { fg = C.overlay0 },
    diffIndexLine = { fg = C.teal },

    healthError = { fg = C.red },
    healthSuccess = { fg = C.teal },
    healthWarning = { fg = C.yellow },

    qfLineNr = { fg = C.yellow },
    qfFileName = { fg = C.blue },
    htmlH1 = { fg = C.pink, style = { "bold" } },
    htmlH2 = { fg = C.blue, style = { "bold" } },
    mkdCodeDelimiter = { bg = C.base, fg = C.text },
    mkdCodeStart = { fg = C.flamingo, style = { "bold" } },
    mkdCodeEnd = { fg = C.flamingo, style = { "bold" } },

    GlyphPalette1 = { fg = C.red },
    GlyphPalette2 = { fg = C.teal },
    GlyphPalette3 = { fg = C.yellow },
    GlyphPalette4 = { fg = C.blue },
    GlyphPalette6 = { fg = C.teal },
    GlyphPalette7 = { fg = C.text },
    GlyphPalette9 = { fg = C.red },

    rainbow1 = { fg = C.red },
    rainbow2 = { fg = C.peach },
    rainbow3 = { fg = C.yellow },
    rainbow4 = { fg = C.green },
    rainbow5 = { fg = C.sapphire },
    rainbow6 = { fg = C.lavender },

    markdownHeadingDelimiter = { fg = C.peach, style = { "bold" } },
    markdownCode = { fg = C.flamingo },
    markdownCodeBlock = { fg = C.flamingo },
    markdownLinkText = { fg = C.blue, style = { "underline" } },
    markdownH1 = { link = "rainbow1" },
    markdownH2 = { link = "rainbow2" },
    markdownH3 = { link = "rainbow3" },
    markdownH4 = { link = "rainbow4" },
    markdownH5 = { link = "rainbow5" },
    markdownH6 = { link = "rainbow6" },
  }

  -- LSP semantic tokens.
  local semantic_tokens = {
    ["@lsp.type.enumMember"] = { fg = C.teal },
    ["@lsp.type.variable"] = {},
    ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
    ["@lsp.typemod.function.builtin"] = { link = "@function.builtin" },
  }

  -- LSP & diagnostics. retro uses gruvbox-conventional info=blue/hint=aqua;
  -- retroplus follows catppuccin (info=sky).
  local diag_error, diag_warn = C.red, C.yellow
  local diag_info = opts.flavor == "plus" and C.sky or C.blue
  local diag_hint, diag_ok = C.teal, C.green
  local d = 0.095 -- darkening for virtual-text backgrounds

  local lsp = {
    LspReferenceText = { bg = C.surface1 },
    LspReferenceRead = { bg = C.surface1 },
    LspReferenceWrite = { bg = C.surface1 },

    DiagnosticVirtualTextError = { bg = darken(diag_error, d), fg = diag_error },
    DiagnosticVirtualTextWarn = { bg = darken(diag_warn, d), fg = diag_warn },
    DiagnosticVirtualTextInfo = { bg = darken(diag_info, d), fg = diag_info },
    DiagnosticVirtualTextHint = { bg = darken(diag_hint, d), fg = diag_hint },
    DiagnosticVirtualTextOk = { bg = darken(diag_hint, d), fg = diag_ok },

    DiagnosticError = { fg = diag_error },
    DiagnosticWarn = { fg = diag_warn },
    DiagnosticInfo = { fg = diag_info },
    DiagnosticHint = { fg = diag_hint },
    DiagnosticOk = { fg = diag_ok },

    DiagnosticUnderlineError = { style = { "undercurl" }, sp = diag_error },
    DiagnosticUnderlineWarn = { style = { "undercurl" }, sp = diag_warn },
    DiagnosticUnderlineInfo = { style = { "undercurl" }, sp = diag_info },
    DiagnosticUnderlineHint = { style = { "undercurl" }, sp = diag_hint },
    DiagnosticUnderlineOk = { style = { "undercurl" }, sp = diag_ok },

    DiagnosticFloatingError = { fg = diag_error },
    DiagnosticFloatingWarn = { fg = diag_warn },
    DiagnosticFloatingInfo = { fg = diag_info },
    DiagnosticFloatingHint = { fg = diag_hint },
    DiagnosticFloatingOk = { fg = diag_ok },

    DiagnosticSignError = { fg = diag_error },
    DiagnosticSignWarn = { fg = diag_warn },
    DiagnosticSignInfo = { fg = diag_info },
    DiagnosticSignHint = { fg = diag_hint },
    DiagnosticSignOk = { fg = diag_ok },

    DiagnosticVirtualLinesError = { fg = diag_error },
    DiagnosticVirtualLinesWarn = { fg = diag_warn },
    DiagnosticVirtualLinesInfo = { fg = diag_info },
    DiagnosticVirtualLinesHint = { fg = diag_hint },
    DiagnosticVirtualLinesOk = { fg = diag_ok },

    LspSignatureActiveParameter = { bg = C.surface0, style = { "bold" } },
    LspCodeLens = { fg = C.overlay0 },
    LspCodeLensSeparator = { link = "LspCodeLens" },
    LspInlayHint = { fg = C.overlay0, bg = darken(C.surface0, 0.64) },
    LspInfoBorder = { link = "FloatBorder" },
  }

  -- mini.nvim.
  local mini = {
    MiniAnimateCursor = { style = { "reverse", "nocombine" } },
    MiniAnimateNormalFloat = { link = "NormalFloat" },

    MiniClueBorder = { link = "FloatBorder" },
    MiniClueDescGroup = { link = "DiagnosticFloatingWarn" },
    MiniClueDescSingle = { link = "NormalFloat" },
    MiniClueNextKey = { link = "DiagnosticFloatingHint" },
    MiniClueNextKeyWithPostkeys = { link = "DiagnosticFloatingError" },
    MiniClueSeparator = { link = "DiagnosticFloatingInfo" },
    MiniClueTitle = { link = "FloatTitle" },

    MiniCompletionActiveParameter = { style = { "underline" } },

    MiniCursorword = { style = { "underline" } },
    MiniCursorwordCurrent = { style = { "underline" } },

    MiniDepsChangeAdded = { link = "diffAdded" },
    MiniDepsChangeRemoved = { link = "diffRemoved" },
    MiniDepsHint = { link = "DiagnosticHint" },
    MiniDepsInfo = { link = "DiagnosticInfo" },
    MiniDepsMsgBreaking = { link = "DiagnosticWarn" },
    MiniDepsPlaceholder = { link = "Comment" },
    MiniDepsTitle = { link = "Title" },
    MiniDepsTitleError = { bg = C.red, fg = C.base },
    MiniDepsTitleSame = { link = "DiffText" },
    MiniDepsTitleUpdate = { bg = C.green, fg = C.base },

    MiniDiffSignAdd = { fg = C.green },
    MiniDiffSignChange = { fg = C.yellow },
    MiniDiffSignDelete = { fg = C.red },
    MiniDiffOverAdd = { link = "DiffAdd" },
    MiniDiffOverChange = { link = "DiffText" },
    MiniDiffOverContext = { link = "DiffChange" },
    MiniDiffOverDelete = { link = "DiffDelete" },

    MiniFilesBorder = { link = "FloatBorder" },
    MiniFilesBorderModified = { link = "DiagnosticFloatingWarn" },
    MiniFilesCursorLine = { link = "CursorLine" },
    MiniFilesDirectory = { link = "Directory" },
    MiniFilesFile = { fg = C.text },
    MiniFilesNormal = { link = "NormalFloat" },
    MiniFilesTitle = { link = "FloatTitle" },
    MiniFilesTitleFocused = { fg = C.subtext0, bg = C.mantle, style = { "bold" } },

    MiniHipatternsFixme = { fg = C.base, bg = C.red, style = { "bold" } },
    MiniHipatternsHack = { fg = C.base, bg = C.yellow, style = { "bold" } },
    MiniHipatternsNote = { fg = C.base, bg = C.sky, style = { "bold" } },
    MiniHipatternsTodo = { fg = C.base, bg = C.teal, style = { "bold" } },

    MiniIconsAzure = { fg = C.sapphire },
    MiniIconsBlue = { fg = C.blue },
    MiniIconsCyan = { fg = C.teal },
    MiniIconsGreen = { fg = C.green },
    MiniIconsGrey = { fg = C.text },
    MiniIconsOrange = { fg = C.peach },
    MiniIconsPurple = { fg = C.mauve },
    MiniIconsRed = { fg = C.red },
    MiniIconsYellow = { fg = C.yellow },

    MiniIndentscopeSymbol = { fg = C.overlay2 },

    MiniJump = { fg = C.overlay2, bg = C.pink },
    MiniJump2dDim = { fg = C.overlay0 },
    MiniJump2dSpot = { bg = C.base, fg = C.peach, style = { "bold", "underline" } },
    MiniJump2dSpotAhead = { bg = C.dim, fg = C.teal },
    MiniJump2dSpotUnique = { bg = C.base, fg = C.sky, style = { "bold" } },

    MiniMapNormal = { link = "NormalFloat" },
    MiniMapSymbolCount = { link = "Special" },
    MiniMapSymbolLine = { link = "Title" },
    MiniMapSymbolView = { link = "Delimiter" },

    MiniNotifyBorder = { link = "FloatBorder" },
    MiniNotifyNormal = { link = "NormalFloat" },
    MiniNotifyTitle = { link = "FloatTitle" },

    MiniOperatorsExchangeFrom = { link = "IncSearch" },

    MiniPickBorder = { link = "FloatBorder" },
    MiniPickBorderBusy = { link = "DiagnosticFloatingWarn" },
    MiniPickBorderText = { fg = C.mauve, bg = C.mantle },
    MiniPickIconDirectory = { link = "Directory" },
    MiniPickIconFile = { link = "MiniPickNormal" },
    MiniPickHeader = { link = "DiagnosticFloatingHint" },
    MiniPickMatchCurrent = { fg = C.flamingo, bg = C.surface0, style = { "bold" } },
    MiniPickMatchMarked = { link = "Visual" },
    MiniPickMatchRanges = { link = "DiagnosticFloatingHint" },
    MiniPickNormal = { link = "NormalFloat" },
    MiniPickPreviewLine = { link = "CursorLine" },
    MiniPickPreviewRegion = { link = "IncSearch" },
    MiniPickPrompt = { fg = C.text, bg = C.mantle },
    MiniPickPromptCaret = { fg = C.flamingo, bg = C.mantle },
    MiniPickPromptPrefix = { fg = C.flamingo, bg = C.mantle },

    MiniStarterCurrent = {},
    MiniStarterFooter = { fg = C.yellow, style = { "italic" } },
    MiniStarterHeader = { fg = C.blue },
    MiniStarterInactive = { fg = C.surface2 },
    MiniStarterItem = { fg = C.text },
    MiniStarterItemBullet = { fg = C.blue },
    MiniStarterItemPrefix = { fg = C.pink },
    MiniStarterSection = { fg = C.flamingo },
    MiniStarterQuery = { fg = C.green },

    MiniStatuslineDevinfo = { fg = C.subtext1, bg = C.surface1 },
    MiniStatuslineFileinfo = { fg = C.subtext1, bg = C.surface1 },
    MiniStatuslineFilename = { fg = C.text, bg = C.mantle },
    MiniStatuslineInactive = { fg = C.blue, bg = C.mantle },
    MiniStatuslineModeCommand = { fg = C.base, bg = C.peach, style = { "bold" } },
    MiniStatuslineModeInsert = { fg = C.base, bg = C.green, style = { "bold" } },
    MiniStatuslineModeNormal = { fg = C.mantle, bg = C.blue, style = { "bold" } },
    MiniStatuslineModeOther = { fg = C.base, bg = C.teal, style = { "bold" } },
    MiniStatuslineModeReplace = { fg = C.base, bg = C.red, style = { "bold" } },
    MiniStatuslineModeVisual = { fg = C.base, bg = C.mauve, style = { "bold" } },

    MiniSurround = { bg = C.pink, fg = C.surface1 },

    MiniTablineCurrent = {
      fg = C.text,
      bg = C.base,
      sp = C.red,
      style = { "bold", "italic", "underline" },
    },
    MiniTablineFill = { bg = C.base },
    MiniTablineHidden = { fg = C.text, bg = C.mantle },
    MiniTablineModifiedCurrent = { fg = C.red, style = { "bold", "italic" } },
    MiniTablineModifiedHidden = { fg = C.red },
    MiniTablineModifiedVisible = { fg = C.red },
    MiniTablineTabpagesection = { fg = C.surface1, bg = C.base },
    MiniTablineVisible = {},

    MiniTestEmphasis = { style = { "bold" } },
    MiniTestFail = { fg = C.red, style = { "bold" } },
    MiniTestPass = { fg = C.green, style = { "bold" } },

    MiniTrailspace = { bg = C.red },
  }

  local treesitter = (opts.flavor == "plus") and treesitter_plus(C) or treesitter_retro(C)

  apply(editor)
  apply(syntax)
  apply(treesitter)
  apply(semantic_tokens)
  apply(lsp)
  apply(mini)
end

return M
