-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
--
--NOTE: Codeium Keymaps
vim.keymap.set("i", "<A-g>", function()
  return vim.fn["codeium#Accept"]()
end, { expr = true, silent = true, desc = "Accept Codeium suggestion" })
vim.keymap.set("i", "<A-]>", function()
  return vim.fn["codeium#CycleCompletions"](1)
end, { expr = true, silent = true, desc = "Cycle to next Codeium suggestion" })
vim.keymap.set("i", "<A-[>", function()
  return vim.fn["codeium#CycleCompletions"](-1)
end, { expr = true, silent = true, desc = "Cycle to previous Codeium suggestion" })
vim.keymap.set("i", "<A-z>", function()
  return vim.fn["codeium#Clear"]()
end, { expr = true, silent = true, desc = "Clear Codeium suggestion" })
vim.keymap.set("n", "<A-q>", function()
  return vim.fn("codeium#Chat()")
end, { expr = true, silent = true, desc = "Open Codeium chat" })
vim.keymap.set("i", "<A-\\>", function()
  return vim.fn("codeium#CycleOrComplet()")
end, { expr = true, silent = true, desc = "Generate Codeium suggestion" })

--NOTE: Inc-Rename Keymaps
vim.keymap.set("n", "<leader>rn", function()
  return ":IncRename " .. vim.fn.expand("<cword>")
end, { expr = true, desc = "Rename variable" })

--NOTE: Buffer Control Keymaps
vim.keymap.set("n", "<C-w>", "<Cmd>bd<CR>", { silent = true, desc = "Delete buffer" })
