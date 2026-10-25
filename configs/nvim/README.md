# 💤 LazyVim

A personalized starter template for [LazyVim](https://github.com/LazyVim/LazyVim). This configuration builds upon the standard LazyVim setup with additional features, plugins, and customizations.

Refer to the original [documentation](https://lazyvim.github.io/installation) to get started with LazyVim.

## ✨ Features

This configuration includes the following additions and modifications:

### General Enhancements

- **[better-escape.nvim](https://github.com/max397574/better-escape.nvim)**: Escape insert mode with `jk` or `jj`.
- **[inc-rename](https://github.com/smjonas/inc-rename.nvim)**: Provides incremental renaming of variables.
- **[mini.surround](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-surround.md)**: For adding, changing, and deleting surroundings (quotes, brackets, etc.).
- **File Explorer**: `neo-tree` is configured to show hidden dotfiles.

### Theming

- **[GitHub Theme](https://github.com/projekt0n/github-nvim-theme)**: The default colorscheme is set to `github_dark`.

### Keymaps

- `<leader>rn`: Rename the variable under the cursor using `IncRename`.
- `<C-w>`: Close the current buffer.

### Language Support & Tooling

- **Formatting**: Code formatting is handled by [Prettier](https://prettier.io/).
- **Snippets**: Utilizes [LuaSnip](https://github.com/L3MON4D3/LuaSnip) with custom snippets for:
  - JavaScript (React, Jest)
  - CSS
- **LSP**:
  - Enhanced settings for `vtsls` for better TypeScript/JavaScript autocompletion.
  - Extra language support for JSON.