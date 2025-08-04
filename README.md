# Personal Dotfiles

This repository contains my personal configuration files and dotfiles for various tools and applications.

## Setup

### Non-Interactive Installation (Default)

To perform a non-interactive installation that applies essential configurations automatically, run:

```bash
./install.sh
```

This will install the following configurations by default:
- Bash configuration (aliases, functions, environment variables)
- Neovim configuration
- SSH configuration
- Superfile configuration

Use this for a quick setup with the most commonly used configurations.

## Directory Structure

- `bin/`: Personal scripts and utilities
- `config/`: Configuration files for various applications
- `install/`: Installation scripts and configurations

## Installation

The repository includes an automated installation script that will set up your environment:

1. Clone this repository to your home directory:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. Run the installation script:
   ```bash
   ./install.sh
   ```

3. Follow the on-screen instructions to complete the setup.

## Configuration


## Configuration

The following configurations can be applied interactively using the `--config` flag:

- **Bash**: Shell configuration including aliases, functions, and environment variables
- **Fonts**: Custom font files for improved terminal and application appearance
- **Ghostty**: Configuration for the Ghostty terminal emulator
- **Kitty**: Configuration for the Kitty terminal emulator with advanced features
- **MPV**: Media player configuration with custom key bindings and settings
- **Neovim**: Modern Vim-based text editor configuration with plugins
- **SSH**: Secure shell configuration for remote server access
- **Superfile**: Terminal file manager configuration

To apply configurations interactively, run:

```bash
./install.sh --config
```

All application configurations are stored in the `config/` directory, organized by application name.

## Available Applications

The following applications can be installed interactively using the `--app` flag:

- **eza**: A modern, maintained replacement for `ls` with better defaults and more features
- **Flatpak**: Package management system with FlatHub repository for desktop applications
- **Neovim**: Hyperextensible Vim-based text editor with a rich plugin ecosystem
- **Starship**: Minimal, blazing-fast, and infinitely customizable shell prompt
- **Superfile**: Modern terminal file manager with a clean and intuitive interface

To install these applications interactively, run:

```bash
./install.sh --app
```
