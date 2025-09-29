return {
  {
    "rafamadriz/friendly-snippets",
    -- add blink.compat to dependencies
    {
      "saghen/blink.compat",
      optional = true, -- make optional so it's only enabled if any extras need it
      opts = {},
      version = not vim.g.lazyvim_blink_main and "*",
    },
  },
  {
    "saghen/blink.cmp",
    commit = "bae4bae0eedd1fa55f34b685862e94a222d5c6f8",
  },
}
