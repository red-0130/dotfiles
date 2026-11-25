# Neovim

A modular Neovim configuration managed with [lazy.nvim](https://github.com/folke/lazy.nvim).

## Features

### General Enhancements

- **[better-escape.nvim](https://github.com/max397574/better-escape.nvim)**: Escape insert mode with `jk` or `jj`.
- **[snacks.nvim](https://github.com/folke/snacks.nvim)**: File explorer (`replace_netrw = true`, shows `.env*`), fuzzy picker, `lazygit`, image viewer, notifier, smooth scroll, and word highlights.
- **[mini.nvim](https://github.com/nvim-mini/mini.nvim)**: `mini.surround` (`gsa`/`gsd`/`gsr`), `mini.pairs`, `mini.move`, `mini.icons`, `mini.indentscope`, `mini.misc`, `mini.tabline`, and `mini.trailspace`.
- **UI & Navigation**: `lualine.nvim`, `noice.nvim`, `which-key.nvim`, `gitsigns.nvim`, `todo-comments.nvim`, `nvim-treesitter`, `nvim-treesitter-textobjects`, and `nvim-ts-autotag`.

### Theming

- **[GitHub Theme](https://github.com/projekt0n/github-nvim-theme)**: Default colorscheme set to `github_dark`.

### Keymaps

- `<leader>qq`: Quit all.
- `<C-s>`: Save file in normal, visual, and insert modes.
- `<leader>yy` / `<leader>pp`: Yank to / put from system clipboard.
- `<leader>e`: Toggle Snacks file explorer.
- `<leader>ff` / `<leader><space>` / `<leader>fs`: Find files (Snacks picker).
- `<leader>sg` / `<leader>/`: Grep across workspace (Snacks picker).
- `<leader>sb` / `<leader>fc` / `<leader>st` / `<leader>sk`: Search buffers, config files, TODOs, and keymaps.

### Language Support & Tooling

- **Completion & Snippets**: [blink.cmp](https://github.com/saghen/blink.cmp) with [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) and custom VS Code-style snippets in `snippets/` (`package.json`) for JavaScript/React/Jest/Redux/Express/JSDoc and CSS.
- **Formatting**: [conform.nvim](https://github.com/stevearc/conform.nvim) with format-on-save (`biome`/`prettierd`/`prettier` for JS/TS/JSON/HTML/Markdown/YAML/CSS, `stylua` for Lua, `shfmt` for Shell, `isort` + `black` for Python, `rustfmt` for Rust, with LSP fallback).
- **LSP**: `nvim-lspconfig` with `mason.nvim`, `mason-lspconfig.nvim`, and `mason-tool-installer.nvim`, configuring `vtsls` for TypeScript/JavaScript and installing `stylua` and `prettier`.
