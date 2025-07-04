# Personal Dotfiles

This repository contains my personal configuration files and dotfiles for various tools and applications.

## Setup

To set up these dotfiles, run the setup script:

```bash
./setup.sh
```
Use the `-i` flag to run the script interactively:



## Directory Structure

- `bashrc/`: Bash configuration files
- `bin/`: Personal scripts and utilities
- `floccus/`: Configuration for Floccus
- `fonts/`: Custom fonts
- `ghostty/`: Ghostty configuration
- `gitconfig/`: Git configuration
- `kitty/`: Kitty terminal configuration
- `mpv/`: MPV media player configuration
- `nvim/`: Neovim configuration
- `ssh/`: SSH configuration
- `superfile/`: Superfile configuration

## Applications

### Bash
Bash configuration files containing:
- Shell settings
- Aliases
- Functions
- Environment variables

#### Custom Functions
Available functions in `bashrc/.config/bashrc/lib/`:

1. `mkcomp` - Creates React components with proper file structure
   - Usage: `mkcomp <component-name>`
   - Example: `mkcomp MyComponent`
   - Creates a component directory with index.js and component file
   - Requires: `src/components` directory in current project

2. `set_space` - DEPRECATED - Use `wsctl` instead
   - Usage: `set_space [path]`
   - Example: `set_space /path/to/project` or `set_space`
   - Saves workspace path to `~/.workspace`
   - Maintains project context across shell sessions

3. `wsctl` - Workspace control utility
   - Usage: `wsctl [command] [args...]`
   - Commands:
     - `set-workspace [path]` - Set workspace path
         - Saves workspace path to `~/.workspace`
     - `set-gemini-api [key]` - Set Gemini API key
         - Saves Gemini API key to `~/.gemini_api`

### Floccus
Configuration for the Floccus bookmark backup application with:
- Bookmark organization
- Backup settings
- Export options
- Sync configuration

### Ghostty
Configuration for Ghostty terminal-based file manager with:
- Key bindings
- Theme settings
- Navigation preferences

### Git
Git configuration files containing:
- User settings
- Aliases
- Custom hooks
- Gitignore patterns

### Kitty
Modern terminal emulator configuration with:
- Custom color schemes
- Font settings
- Key bindings
- Window and tab management
- Performance optimizations

### MPV
Custom configuration for the MPV media player with:
- Custom key bindings
- Video and audio settings
- Playback controls
- Interface customization

### Neovim
Advanced text editor configuration featuring:
- Custom key mappings
- Plugin management
- Syntax highlighting
- File type specific settings
- UI enhancements

### SSH
SSH configuration containing:
- Host-specific settings
- Authentication methods
- Network configurations
- Security settings

### Superfile
Configuration for Superfile with:
- File handling preferences
- Custom actions
- Integration settings

## License

This project is licensed under the MIT License - see the LICENSE file for details.