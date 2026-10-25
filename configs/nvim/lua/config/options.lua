-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)

-- Hide vim mode
vim.opt.showmode = false

-- Confirm quit
vim.opt.confirm = true

-- Auto format
vim.g.autoformat = true

-- Snacks animation
vim.g.snacks_animate = true

-- Show the current document symbols location from Trouble in lualine
-- You can disable this for a buffer by setting `vim.b.trouble_lualine = false`
vim.g.trouble_lualine = false

-- Show line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Tabbing config
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.shiftwidth = 2 -- Amount to indent with << and >>
vim.opt.shiftround = true
vim.opt.softtabstop = 2 -- How manyspaces are applied when pressing Tab
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

-- Various UI config
vim.opt.smoothscroll = true
vim.opt.spelllang = { "en" }
vim.opt.termguicolors = true
vim.opt.timeoutlen = vim.g.vscode and 1000 or 300
vim.opt.undofile = true
vim.opt.updatetime = 200
vim.opt.winminwidth = 5
vim.g.markdown_recommended_style = 0

-- Show active line
vim.opt.cursorline = true

-- Enable break indent
vim.opt.linebreak = true
vim.opt.breakindent = true

-- Case-insensitive searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Folds config
vim.opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
vim.opt.foldlevel = 99
vim.opt.foldmethod = "indent"
vim.opt.foldtext = ""
vim.opt.conceallevel = 2

-- Default splitting behaviour
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Minimal number of screen lines to keep above and below the cursor
vim.opt.scrolloff = 10

-- Disable commandline until it is needed
-- vim.opt.cmdheight = 0

-- Highlight text for some time after yanking
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
  pattern = "*",
  callback = function()
    vim.highlight.on_yank()
  end,
  desc = "Highlight yank",
})

-- Clipboard config
vim.opt.autowrite = true
vim.opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"

-- Diagnostics config
vim.diagnostic.config({
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },

  -- Can switch between these as you prefer
  virtual_text = true, -- Text shows up at the end of the line
  virtual_lines = false, -- Text shows up underneath the line, with virtual lines

  -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
  jump = { float = true },
})
