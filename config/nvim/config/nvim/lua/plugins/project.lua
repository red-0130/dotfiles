return {
  "DrKJeff16/project.nvim",
  dependencies = { -- OPTIONAL. Choose any of the following
    "folke/snacks.nvim",
  },
  opts = {
    patterns = {
      ".git",
      ".github",
      "_darcs",
      ".hg",
      ".bzr",
      ".svn",
      "Pipfile",
      "pyproject.toml",
      ".pre-commit-config.yaml",
      ".pre-commit-config.yml",
      ".csproj",
      ".sln",
      ".nvim.lua",
      ".neoconf.json",
      "neoconf.json",
      "Cargo.toml",
      "package.json",
    },
    snacks = {
      enabled = true, -- Will enable the `:Project snacks` command
      opts = {
        sort = "newest",
        hidden = false,
        title = "Select Project",
        layout = "select",
        -- icon = {},
        -- path_icons = {},
      },
    },
  },
}
