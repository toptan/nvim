-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- For conciseness
local opts = { noremap = true, silent = true }

-- INFO: Using semicolon to enter command mode.
vim.keymap.set("", ";", ":", opts)

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", opts)

-- delete single character without copying into register
vim.keymap.set("n", "x", '"_x', opts)

-- Keep last yanked when pasting
vim.keymap.set("v", "p", '"_dP', opts)

-- vim.keymap.set(
--     "n",
--     "<leader>td",
--     (function()
--         local diag_status = 1 -- 1 is show; 0 is hide
--         return function()
--             if diag_status == 1 then
--                 diag_status = 0
--                 vim.diagnostic.hide()
--             else
--                 diag_status = 1
--                 vim.diagnostic.show()
--             end
--         end
--     end)(),
--     {
--         desc = "[D]iagnostics",
--     }
-- )

vim.keymap.set("n", "gl", function()
  vim.diagnostic.open_float()
end, { desc = "Open Diagnostics in Float" })

-- vim.keymap.set("n", "<leader>cf", function()
--     require("conform").format({
--         lsp_format = "fallback",
--     })
-- end, { desc = "[F]ormat" })

vim.keymap.set(
  "n",
  "<leader>tl",
  (function()
    local diag_status = 1 -- 1 is show; 0 is hide
    return function()
      if diag_status == 1 then
        diag_status = 0
        vim.diagnostic.config({ virtual_lines = false, virtual_text = true })
      else
        diag_status = 1
        vim.diagnostic.config({ virtual_lines = true, virtual_text = false })
      end
    end
  end)(),
  {
    desc = "Virtual [L]ines/Text",
  }
)

-- Keybinds to make split navigation easier
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- Buffer navigation
vim.keymap.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })

-- Stay in indent mode
vim.keymap.set("v", "<", "<gv", { desc = "Decrease indent" })
vim.keymap.set("v", ">", ">gv", { desc = "Increase indent" })

-- Move line/selection up and down
vim.keymap.set("n", "<M-j>", ":m .+1<cr>==", { desc = "Move line down" })
vim.keymap.set("n", "<M-k>", ":m .-2<cr>==", { desc = "Move line up" })
vim.keymap.set("v", "<M-j>", ":m '>+1<cr>gv=gv", { desc = "Move line down" })
vim.keymap.set("v", "<M-k>", ":m '<-2<cr>gv=gv", { desc = "Move line up" })
vim.keymap.set("i", "<M-j>", "<Esc>:m .+1<cr>==gi", { desc = "Move line down" })
vim.keymap.set("i", "<M-k>", "<Esc>:m .-2<cr>==gi", { desc = "Move line up" })

vim.keymap.set("n", "<A-j>", ":m .+1<cr>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-k>", ":m .-2<cr>==", { desc = "Move line up" })
vim.keymap.set("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move line down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move line up" })
vim.keymap.set("i", "<A-j>", "<Esc>:m .+1<cr>==gi", { desc = "Move line down" })
vim.keymap.set("i", "<A-k>", "<Esc>:m .-2<cr>==gi", { desc = "Move line up" })

-- Toggling precognition and hardtime plugins
-- vim.keymap.set("n", "<leader>tt", "<cmd>Hardtime toggle<cr>", { desc = "Hard [T]ime" })
-- vim.keymap.set("n", "<leader>tp", "<cmd>Precognition toggle<cr>", { desc = "[P]recognition" })
