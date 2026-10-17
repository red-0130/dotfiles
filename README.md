# Dotfiles

A modular, automated dotfiles and development environment setup for Linux. Features an interactive terminal UI for picking applications and configurations, as well as one-command non-interactive defaults.

---

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/red-0130/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 2. Run the setup script

```bash
./setup.sh
```

---

## Usage

The `./setup.sh` script provides several ways to install configurations and applications:

### 1. Default Non-Interactive Installation

Running `./setup.sh` with no arguments applies essential core configurations automatically (making automatic backups of existing configs first in `~/.config.bak`):

```bash
./setup.sh
```

**Configurations applied by default:**
* `bashrc` — Shell aliases, functions, environment variables, and workspace utilities
* `nvim` — Modern Neovim configuration with LSP and plugins
* `ssh` — SSH client configuration (including Coder CLI integration)
* `superfile` — Modern terminal file manager configuration
* `gitconfig` — Git global aliases and defaults
* `zellij` — Terminal multiplexer configuration

---

### 2. Interactive Configuration Selector (`-c` / `--config`)

Launch an interactive terminal multi-select menu to choose exactly which configurations to apply:

```bash
./setup.sh --config
# or
./setup.sh -c
```

---

### 3. Interactive Application Installer (`-a` / `--app`)

Launch an interactive terminal multi-select menu to choose applications, package managers, and development tools to install on your system:

```bash
./setup.sh --app
# or
./setup.sh -a
```

---

### 4. Direct Configuration by Name

Apply one or multiple specific configurations directly by passing their names:

```bash
./setup.sh nvim zellij
./setup.sh fonts ghostty starship
```

### 5. Help

View all available flags and usage instructions:

```bash
./setup.sh --help
```

---

## Available Configurations

All configuration files are stored in the `config/` directory:

| Configuration | Description | Key Details |
| :--- | :--- | :--- |
| `bashrc` | Shell aliases, functions & environment | Aliases (`eza`, `git`, `batcat`, `coder`, `podman`), workspace switcher (`wsctl`), subnet matcher (`onsubnet`), custom PS1 prompt |
| `fonts` | Nerd Fonts collection | JetBrains Mono Nerd Font suite (Regular, Bold, Light, Mono, Propo) installed to `~/.local/share/fonts` |
| `ghostty` | Terminal emulator configuration | GPU-accelerated terminal config with JetBrains Mono Nerd Font, GitHub Dark theme, window padding, and blur |
| `gitconfig` | Global Git configuration | Common aliases (`st`, `co`, `br`, `lg`), `pull.rebase = true`, `push.autoSetupRemote = true` |
| `kitty` | Terminal emulator configuration | Dracula theme, transparency, JetBrains Mono Nerd Font |
| `mpv` | Media player configuration | Custom ModernZ UI (`modernz.lua`), seekbar thumbnail previews (`thumbfast.lua`), and YouTube downloader (`youtube-download.lua`) |
| `nvim` | Modern Neovim IDE configuration | Lazy.nvim package manager, LSP support, conform.nvim formatting, blink.cmp completion, snacks.nvim, treesitter, and which-key |
| `ssh` | SSH client configuration | Coder CLI SSH workspace integration |
| `starship` | Cross-shell prompt | Custom Rose Pine palette, git branch & status indicators, runtime versions, command duration |
| `superfile` | Terminal file manager | OneDark theme, Nerd Font icons, automatic directory changes on quit |
| `zellij` | Terminal workspace multiplexer | Session management, custom keybindings, floating windows, Catppuccin styling |

---

## Available Applications

The installer scripts in `install_scripts/` can be run interactively (`./setup.sh --app`) or individually:

| Application | Description | Category |
| :--- | :--- | :--- |
| **batcat** | A `cat` clone with syntax highlighting and Git integration | CLI Tools |
| **eza** | A modern, maintained replacement for `ls` with colors and icons | CLI Tools |
| **fd** | Simple, fast, and user-friendly alternative to `find` | CLI Tools |
| **fzf** | Command-line interactive fuzzy finder | CLI Tools |
| **ripgrep** | Extremely fast search tool respecting gitignore rules | CLI Tools |
| **superfile** | Modern, elegant terminal file manager | CLI Tools |
| **wormhole** | Securely send files between computers via Magic Wormhole | CLI Tools |
| **zellij** | Fast, extensible terminal multiplexer with batteries included | Terminal & Workspace |
| **ghostty** | Fast, feature-rich, GPU-accelerated terminal emulator | Terminal & Workspace |
| **starship** | Minimal, blazing-fast, and infinitely customizable shell prompt | Shell & Prompts |
| **git** | Installs latest version of Git | Development |
| **lazygit** | Simple and intuitive terminal UI for Git commands | Development |
| **nvim** | Extensible Neovim editor with full Lua ecosystem | Development |
| **treesitter** | Incremental parsing system CLI for programming languages | Development |
| **bun** | Fast, all-in-one JavaScript runtime, bundler, and package manager | Languages & Runtimes |
| **nvm** | Node Version Manager for managing multiple Node.js versions | Languages & Runtimes |
| **rust** | Rust programming language toolchain and Cargo package manager | Languages & Runtimes |
| **uv** | Extremely fast Python package manager and resolver | Languages & Runtimes |
| **flatpak** | Universal Linux package management system with FlatHub | Package Managers |
| **helium** | Privacy-focused and hardened Chromium-based web browser | Browsers |
| **thorium** | High-performance, compiler-optimized Chromium-based browser | Browsers |

---

## Directory Structure

```text
dotfiles/
├── bin/                          # Helper scripts (logging, backup, TUI multiselect)
│   ├── apply_config.sh
│   ├── backup.sh
│   ├── interactive_app_install.sh
│   ├── interactive_config_install.sh
│   ├── log.sh
│   ├── multiselect.sh
│   ├── path_exist.sh
│   └── update_repo.sh
├── config/                       # Application configuration files
│   ├── bashrc/
│   ├── fonts/
│   ├── ghostty/
│   ├── gitconfig/
│   ├── kitty/
│   ├── mpv/
│   ├── nvim/
│   ├── ssh/
│   ├── starship/
│   ├── superfile/
│   └── zellij/
├── install_scripts/              # Automated installation scripts for tools & apps
└── setup.sh                      # Main entrypoint script
```

---

## Backups

Before applying configurations, the setup script automatically creates backups of any existing configurations in `~/.config.bak/`, keeping your previous settings safe.
