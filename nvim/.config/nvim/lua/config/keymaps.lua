-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
--
--NOTE: Inc-Rename Keymaps
vim.keymap.set("n", "<leader>rn", function()
  return ":IncRename " .. vim.fn.expand("<cword>")
end, { expr = true, desc = "Rename variable" })

--NOTE: Buffer Control Keymaps
vim.keymap.set("n", "<C-w>", "<Cmd>bd<CR>", { silent = true, desc = "Delete buffer" })
