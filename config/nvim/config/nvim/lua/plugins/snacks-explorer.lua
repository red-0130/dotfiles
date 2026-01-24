return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          exclude = { "node_modules" },
          include = { ".env*" },
          layout = {
            layout = {
              position = "right",
            },
          },
        },
      },
    },
  },
}
