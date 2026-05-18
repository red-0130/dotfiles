return {
  "nvim-mini/mini.misc",
  version = false,
  config = function()
    require("mini.misc").setup_auto_root({
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
    })
  end,
}
