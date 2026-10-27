# Dotfiles Installer

A modular, robust, and extensible dotfiles installer compliant with the [GitHub Codespaces and Dev Containers dotfiles standard](https://docs.github.com/en/codespaces/customizing-your-codespace/personalizing-github-codespaces-for-your-account).

---

## Features

- **GitHub Codespaces & Dev Containers Compliant**: When executed without flags (unattended), it non-interactively installs predefined configurations (`bash`, `bash_scripts`, `git`), creates backups of conflicting files, and exits cleanly with code `0`.
- **Interactive Configuration Selector (`-c`, `--config`)**: Terminal checkbox interface where you can navigate, toggle, and install select configurations.
- **Interactive Application Installer (`-a`, `--app`)**: Terminal interface allowing you to choose which development tools and CLI utilities to install on the system.
- **Safe & Idempotent**: Conflicting files are automatically backed up with timestamps to `~/.dotfiles_backup/`. Existing identical symlinks are recognized and left untouched.
- **Zero-Dependency Interactive TUI**: Pure Bash checklist with arrow key navigation, Space toggling, 'a' toggle-all, and Enter confirmation, with fallback to numbered prompts on dumb/piped terminals.
- **Extensible Architecture**: Modular scripts in `lib/`, simple folder-based configs in `configs/`, and standalone installation scripts in `apps/`.

---

## Directory Structure

```text
dotfiles/
├── install.sh                  # Main executable entry point
├── dotfiles.conf               # User configuration (predefined apps, backup dir)
├── configs/                    # Application configurations (named after app)
│   ├── bash/                   # Bash config (.bash_aliases, .bashrc)
│   ├── bash_scripts/           # Custom shell helper scripts & tools
│   ├── ghostty/                # Ghostty terminal emulator config
│   ├── git/                    # Git config (config, ignore)
│   ├── mpv/                    # MPV media player config & scripts
│   ├── neovim/                 # Neovim config (init.lua, LazyVim)
│   ├── ssh/                    # SSH client config & setup script
│   ├── starship/               # Starship prompt config (starship.toml)
│   ├── superfile/              # Superfile terminal file manager config
│   └── zellij/                 # Zellij terminal workspace config (config.kdl)
├── apps/                       # Application installation scripts
│   ├── antigravity.sh
│   ├── bat.sh
│   ├── bun.sh
│   ├── eza.sh
│   ├── fd.sh
│   ├── flatpak.sh
│   ├── fzf.sh
│   ├── gh.sh
│   ├── ghostty.sh
│   ├── git.sh
│   ├── helium.sh
│   ├── lazygit.sh
│   ├── neovim.sh
│   ├── nvm.sh
│   ├── ripgrep.sh
│   ├── rust.sh
│   ├── starship.sh
│   ├── superfile.sh
│   ├── tree-sitter.sh
│   ├── uv.sh
│   ├── zellij.sh
│   └── zsh.sh
└── lib/                        # Core installer libraries
    ├── utils.sh                # Logging, styling, and OS/package detection
    ├── backup.sh               # Conflicting files backup manager
    ├── link.sh                 # Safe symlink creator
    ├── config_installer.sh     # Configuration installer & resolver
    ├── app_installer.sh        # Application installer & executor
    └── ui.sh                   # Interactive checklist terminal UI
```

---

## Usage

### 1. Default (GitHub Dotfiles Mode)
When invoked without arguments (such as during GitHub Codespaces container startup), the script installs the predefined configurations configured in `dotfiles.conf` (`bash`, `bash_scripts`, `git`):

```bash
./install.sh
```

### 2. Interactive Configuration Selection
Launch the interactive checklist to select which configurations to link:

```bash
./install.sh -c
# or
./install.sh --config
```

**Controls in Interactive Terminal:**
- `↑` / `↓` or `k` / `j`: Move up and down
- `Space`: Toggle selected item
- `a`: Toggle all items on/off
- `Enter`: Confirm and install selected items
- `q` or `Esc`: Cancel without installing

### 3. Interactive Application Installation
Launch the interactive checklist to select CLI applications to install:

```bash
./install.sh -a
# or
./install.sh --app
```

### 4. Direct / Scriptable Installation
Install specific configurations or applications directly without interactive prompts:

```bash
# Install specific configs
./install.sh -c git bash neovim

# Install specific apps
./install.sh -a ripgrep fzf starship

# Install all available configurations
./install.sh --all
```

### 5. Listing Available Items
List all discovered configurations in `configs/` and installable applications in `apps/`:

```bash
./install.sh --list
```

---

## Adding Configurations

Configs are stored in the `configs/` directory and named after the app it belongs to.

### Automatic Linking Rules:
1. **Custom `install.sh`**: If `configs/<app>/install.sh` exists, it will be executed.
2. **Explicit Target `.target`**: If `configs/<app>/.target` exists, you can specify destination paths:
   ```text
   # In configs/<app>/.target:
   ~/.config/<app>
   # Or file-by-file mapping:
   custom.conf:~/.custom.conf
   ```
3. **Dotfiles**: Files starting with `.` (e.g., `.bashrc`, `.zshrc`) are symlinked directly to `$HOME/<filename>`.
4. **Known Core Tools**:
   - `git` -> `~/.gitconfig`, `~/.gitignore_global`
   - `bash` -> `~/.bashrc`, `~/.bash_aliases`
   - `zsh` -> `~/.zshrc`
5. **Modern XDG Apps**: Any folder (e.g. `configs/zellij`, `configs/ghostty`, `configs/superfile`) is symlinked to `~/.config/<app>`.

---

## Adding Applications

To add an application installer:
1. Create a script `apps/<app_name>.sh` (make it executable: `chmod +x`).
2. Add metadata comments at the top:
   ```bash
   #!/usr/bin/env bash
   # description: High-performance command runner
   # command: runner
   set -e
   DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
   source "$DIR/lib/utils.sh"

   if has_cmd runner; then
       log_success "runner is already installed"
       exit 0
   fi

   # Installation commands here (apt, brew, curl, etc.)
   ```
3. It will automatically show up in the interactive menu and `--list`.
