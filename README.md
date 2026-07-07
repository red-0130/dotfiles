# Personal Dotfiles

This repository contains my personal configuration files and dotfiles for various tools and applications.

## Setup

### Non-Interactive Installation (Default)

To perform a non-interactive installation that applies essential configurations automatically, run:

```bash
./setup.sh
```

This will install the following configurations by default:
- Bash configuration (`bashrc` - aliases including Coder CLI, functions, environment variables)
- Neovim configuration (`nvim`)
- SSH configuration (`ssh`)
- Superfile configuration (`superfile`)
- Git configuration (`gitconfig` - custom aliases and settings)
- Zellij configuration (`zellij` - terminal workspace multiplexer)

Use this for a quick setup with the most commonly used configurations.

## Directory Structure

- [bin/](file:///home/coder/dotfiles/bin): Personal scripts and utilities
- [config/](file:///home/coder/dotfiles/config): Configuration files for various applications
- [install_scripts/](file:///home/coder/dotfiles/install_scripts): Installation scripts and configurations

## Installation

The repository includes an automated setup script that will set up your environment:

1. Clone this repository to your home directory:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. Run the setup script:
   ```bash
   ./setup.sh
   ```

3. Follow the on-screen instructions if prompted, or let the script run to completion.

## Configuration

The following configurations can be applied interactively using the `--config` or `-c` flag:

- **bashrc**: Shell configuration including aliases (e.g., Coder CLI, Git, eza, and Podman), functions, and environment variables
- **fonts**: Custom font files for improved terminal and application appearance
- **ghostty**: Configuration for the Ghostty terminal emulator
- **kitty**: Configuration for the Kitty terminal emulator with advanced features
- **mpv**: Media player configuration with custom key bindings and settings
- **nvim**: Modern Vim-based text editor configuration with plugins
- **ssh**: Secure shell configuration for remote server access
- **starship**: Cross-shell prompt configuration for a customized shell experience
- **superfile**: Terminal file manager configuration
- **zellij**: Terminal workspace/multiplexer configuration

To apply configurations interactively, run:

```bash
./setup.sh --config
# or
./setup.sh -c
```

All application configurations are stored in the [config/](file:///home/coder/dotfiles/config) directory, organized by application name.

*(Note: Browser bookmarks are stored in [config/floccus/floccus.export.json](file:///home/coder/dotfiles/config/floccus/floccus.export.json) for import via Floccus).*

## Available Applications

The following applications can be installed interactively using the `--app` or `-a` flag:

- **batcat**: A `cat` clone with syntax highlighting and Git integration
- **bun**: A fast, all-in-one JavaScript runtime and package manager
- **eza**: A modern, maintained replacement for `ls` with better defaults and more features
- **fd**: A simple, fast, and user-friendly alternative to `find`
- **Flatpak**: Package management system with FlatHub repository for desktop applications
- **fzf**: A command-line fuzzy finder
- **Ghostty**: Fast and feature-rich terminal emulator
- **git**: Installs the latest version of Git
- **helium**: Private and secured chromium-based browser
- **lazygit**: Simple terminal UI for git commands
- **Neovim**: Hyperextensible Vim-based text editor with a rich plugin ecosystem
- **nvm**: Node Version Manager for managing multiple Node.js versions
- **ripgrep**: A fast recursive search tool that respects gitignore
- **rust**: Rust programming language toolchain and Cargo package manager
- **Starship**: Minimal, blazing-fast, and infinitely customizable shell prompt
- **Superfile**: Modern terminal file manager with a clean and intuitive interface
- **thorium**: A high-performance, privacy-focused web browser
- **treesitter**: An incremental parsing system for programming tools
- **wormhole**: A simple and secure way to send files between computers
- **Zellij**: A terminal workspace/multiplexer with batteries included

To install these applications interactively, run:

```bash
./setup.sh --app
# or
./setup.sh -a
```