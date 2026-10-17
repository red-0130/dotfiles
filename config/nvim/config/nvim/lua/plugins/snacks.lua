return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    image = { enabled = true },
    lazygit = { enabled = true },
    explorer = { enabled = true, replace_netrw = true, trash = true },
    scroll = { enabled = true },
    statuscolumn = {
      enabled = true,
    },
    notifier = { enabled = true },
    words = { enabled = true },
    picker = {
      enabled = true,
      win = {
        preview = {
          wo = {
            wrap = true,
            linebreak = true,
            showbreak = " ",
          },
        },
      },
      sources = {
        keymaps = {
          layout = { preset = "vscode" },
        },
        todo_comments = {
          layout = { preset = "ivy" },
        },
        explorer = {
          -- explorer picker configuration here
          git_status = true,
          auto_close = true,
          exclude = { "node_modules" },
          include = { ".env*" },
          layout = {
            -- preset = "vscode",
            -- position = "right"
          },
        },
      },
    },
  },
}
