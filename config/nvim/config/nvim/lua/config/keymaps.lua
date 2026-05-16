-- QoL keybindings
vim.keymap.set("n", "<leader>qq", ":qa<CR>", { silent = true, desc = "Quit" })
-- Yanking and Putting to and from clipboard
vim.keymap.set("v", "<leader>yy", '"+y', { desc = "Yank to registry" })
vim.keymap.set("n", "<leader>pp", '"+p', { desc = "Put from clipboard" })
-- Save in normal, visual, and insert mode
vim.keymap.set("n", "<C-s>", ":update<CR>", { silent = true, desc = "Save file while in normal mode" })
vim.keymap.set("v", "<C-s>", ":update<CR>", { silent = true, desc = "Save file while in visual mode" })
vim.keymap.set("i", "<C-s>", "<Esc>:update<CR>", { silent = true, desc = "Save file while in insert mode" })

-- Picker keymaps
vim.keymap.set("n", "<leader>e", function()
  Snacks.explorer()
end, { desc = "Open Explorer" })

vim.keymap.set("n", "<leader>fs", function()
  Snacks.picker.smart()
end, { desc = "Smart Find Files" })

vim.keymap.set("n", "<leader>ff", function()
  Snacks.picker.files()
end, { desc = "Find files" })

vim.keymap.set("n", "<leader><space>", function()
  Snacks.picker.files()
end, { desc = "Find files" })

vim.keymap.set("n", "<leader>sg", function()
  Snacks.picker.grep()
end, { desc = "Grep" })

vim.keymap.set("n", "<leader>/", function()
  Snacks.picker.grep()
end, { desc = "Grep" })

vim.keymap.set("n", "<leader>sb", function()
  Snacks.picker.buffers()
end, { desc = "Search Buffers" })

vim.keymap.set("n", "<leader>fc", function()
  Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find Config File" })

vim.keymap.set("n", "<leader>st", function()
  Snacks.picker.todo_comments()
end, { desc = "Search for TODOs" })

vim.keymap.set("n", "<leader>sk", function()
  Snacks.picker.keymaps()
end, { desc = "Search for keymaps" })

vim.keymap.set("n", "<leader>gb", function()
  Snacks.picker.git_branches({
    layout = {
      preset = "ivy", -- or "select", "vscode", etc.
    },
  })
end, { desc = "Show git branches" })

vim.keymap.set("n", "<leader>sp", function()
  Snacks.picker.projects()
end, { desc = "Search projects" })

vim.keymap.set("n", "gd", function()
  Snacks.picker.lsp_definitions()
end, { desc = "Go to [d]efinition" })

vim.keymap.set("n", "gr", function()
  Snacks.picker.lsp_references()
end, { desc = "Go to [r]eference" })

vim.keymap.set("n", "gi", function()
  Snacks.picker.lsp_implementations()
end, { desc = "Go to [i]mplementation" })

vim.keymap.set("n", "gy", function()
  Snacks.picker.lsp_type_definitions()
end, { desc = "Go to T[y]pe definition" })

vim.keymap.set("n", "<leader>sd", function()
  Snacks.picker.diagnostics()
end, { desc = "Search for diagnostics" })

-- Lazygit keymaps
vim.keymap.set("n", "<leader>gg", function()
  Snacks.lazygit()
end, { desc = "Open Lazygit" })

-- Diagnostics keymap
vim.keymap.set("n", "<leader>cd", function()
  vim.diagnostic.open_float()
end, { desc = "Open diagnostics" })

-- Code actions
vim.keymap.set({ "n", "x" }, "<leader>cc", vim.lsp.buf.code_action, { desc = "Show available code actions" })
vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Code action rename" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Code action rename" })
vim.keymap.set("n", "<leader>cf", function()
  require("conform").format({ async = true })
end, { desc = "Format code" })

-- Buffer keymaps
vim.keymap.set("n", "<leader>bd", ":bd<Enter>", { desc = "[b]uffer [d]elete" })

-- Package manager keymaps
vim.keymap.set("n", "<leader>ll", ":Lazy<Enter>", { desc = "Open Lazy plugin manager" })
vim.keymap.set("n", "<leader>lm", ":Mason<Enter>", { desc = "Open Mason LSP package manager" })
