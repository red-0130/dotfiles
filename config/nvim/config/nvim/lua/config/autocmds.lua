-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
-- Autohide Tabline
vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter" }, {
  callback = function()
    local listed_buffers = vim.api.nvim_list_bufs()
    local count = 0
    for _, buf in ipairs(listed_buffers) do
      if vim.bo[buf].buflisted then
        count = count + 1
      end
    end
    vim.o.showtabline = count > 1 and 2 or 0
  end,
  group = vim.api.nvim_create_augroup("TablineAutoHide", { clear = true }),
})
