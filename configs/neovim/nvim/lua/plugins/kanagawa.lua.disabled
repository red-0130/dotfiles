return {
  "rebelot/kanagawa.nvim",
  lazy = false, -- Load immediately at startup
  priority = 1000, -- Ensure it loads before other plugins
  config = function()
    require("kanagawa").setup({
      -- Optional: Customize settings (e.g., transparent background)
      -- transparent = true,
      terminalColors = true,
      undercurl = true,
      commentStyle = { italic = true },
      theme = "dragon",
      background = {
        dark = "dragon",
        light = "lotus",
      },
      -- colors = {
      --   theme = {
      --     all = {
      --       ui = {
      --         bg_gutter = "none",
      --       },
      --     },
      --   },
      -- },
    })
    vim.cmd("colorscheme kanagawa") -- Apply the default wave variant
    -- Alternative variants: "kanagawa-wave", "kanagawa-dragon", or "kanagawa-lotus"
  end,
}
