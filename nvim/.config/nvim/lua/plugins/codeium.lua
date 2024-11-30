return {
  {
    "Exafunction/codeium.vim",
    config = function()
      vim.g.codeium_disable_bindings = 1
      vim.g.codeium_manual = true
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    event = "VeryLazy",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 2, "codeium#GetStatusString")
    end,
  },
}
