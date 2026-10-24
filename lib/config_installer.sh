#!/usr/bin/env bash
# ==============================================================================
# lib/config_installer.sh - Config discovery and installation
# ==============================================================================

get_available_configs() {
    local configs=()
    if [[ -d "$CONFIG_DIR" ]]; then
        for item in "$CONFIG_DIR"/*; do
            [[ -e "$item" ]] || continue
            local name
            name="$(basename "$item")"
            # Ignore hidden files, READMEs, licenses, docs
            [[ "$name" == .* ]] && continue
            [[ "$name" == "README"* ]] && continue
            [[ "$name" == "LICENSE"* ]] && continue
            configs+=("$name")
        done
    fi
    printf '%s\n' "${configs[@]}"
}

get_config_description() {
    local app="$1"
    local desc_file="$CONFIG_DIR/$app/.description"
    if [[ -f "$desc_file" ]]; then
        head -n 1 "$desc_file"
        return 0
    fi

    # Built-in friendly descriptions
    case "$app" in
        bash)     echo "Bash shell configuration and aliases (~/.bashrc, ~/.bash_aliases)" ;;
        git)      echo "Git configuration and global ignore rules (~/.gitconfig)" ;;
        tmux)     echo "Tmux terminal multiplexer settings (~/.tmux.conf)" ;;
        nvim)     echo "Neovim editor configuration (~/.config/nvim)" ;;
        starship) echo "Cross-shell customizable prompt (~/.config/starship.toml)" ;;
        zsh)      echo "Zsh shell configuration and theme (~/.zshrc)" ;;
        vim)      echo "Vim editor configuration (~/.vimrc)" ;;
        gh)       echo "GitHub CLI configuration (~/.config/gh)" ;;
        bat)      echo "Bat cat-clone syntax highlighter configuration" ;;
        alacritty)echo "Alacritty terminal emulator configuration" ;;
        kitty)    echo "Kitty terminal emulator configuration" ;;
        *)        echo "Configuration files for ${app}" ;;
    esac
}

install_single_config() {
    local app="$1"
    local src="$CONFIG_DIR/$app"

    if [[ ! -e "$src" ]]; then
        log_error "Config for '$app' not found in $CONFIG_DIR"
        return 1
    fi

    log_step "Installing config for: ${COLOR_BOLD}${app}${COLOR_RESET}"

    # 1. Custom install hook inside config directory
    if [[ -f "$src/install.sh" && -x "$src/install.sh" ]]; then
        log_info "Running custom install hook for $app..."
        "$src/install.sh"
        return $?
    fi

    # 2. Custom .target file
    if [[ -f "$src/.target" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Trim whitespace
            line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            [[ -z "$line" || "$line" == \#* ]] && continue

            # Format can be: "target_path" OR "relative_src:target_path"
            if [[ "$line" == *":"* ]]; then
                local sub_src="${line%%:*}"
                local target="${line#*:}"
                safe_symlink "$src/$sub_src" "$target"
            else
                safe_symlink "$src" "$line"
            fi
        done < "$src/.target"
        return 0
    fi

    # 3. Known application-specific link conventions
    case "$app" in
        bash)
            local linked_any=false
            local linked_files=()

            # First check common bash config files without dot
            for bf in bashrc bash_aliases bash_profile; do
                if [[ -f "$src/$bf" ]]; then
                    safe_symlink "$src/$bf" "$HOME/.$bf"
                    linked_any=true
                    linked_files+=("$bf")
                fi
            done

            # Then link all dotfiles in configs/bash/
            shopt -s nullglob
            for f in "$src"/.*; do
                local fname="$(basename "$f")"
                [[ "$fname" == "." || "$fname" == ".." || "$fname" == ".target" || "$fname" == ".description" ]] && continue
                safe_symlink "$f" "$HOME/$fname"
                linked_any=true
            done
            shopt -u nullglob
            $linked_any && return 0
            ;;

        git)
            local linked_any=false
            if [[ -f "$src/.gitconfig" ]]; then
                safe_symlink "$src/.gitconfig" "$HOME/.gitconfig"
                linked_any=true
            elif [[ -f "$src/gitconfig" ]]; then
                safe_symlink "$src/gitconfig" "$HOME/.gitconfig"
                linked_any=true
            elif [[ -f "$src/config" ]]; then
                safe_symlink "$src/config" "$HOME/.gitconfig"
                linked_any=true
            fi

            if [[ -f "$src/.gitignore_global" ]]; then
                safe_symlink "$src/.gitignore_global" "$HOME/.gitignore_global"
                linked_any=true
            elif [[ -f "$src/gitignore_global" ]]; then
                safe_symlink "$src/gitignore_global" "$HOME/.gitignore_global"
                linked_any=true
            elif [[ -f "$src/ignore" ]]; then
                safe_symlink "$src/ignore" "$HOME/.gitignore_global"
                linked_any=true
            fi
            $linked_any && return 0
            ;;

        tmux)
            if [[ -f "$src/.tmux.conf" ]]; then
                safe_symlink "$src/.tmux.conf" "$HOME/.tmux.conf"
                return 0
            elif [[ -f "$src/tmux.conf" ]]; then
                safe_symlink "$src/tmux.conf" "$HOME/.tmux.conf"
                return 0
            fi
            ;;

        zsh)
            if [[ -f "$src/.zshrc" ]]; then
                safe_symlink "$src/.zshrc" "$HOME/.zshrc"
                return 0
            elif [[ -f "$src/zshrc" ]]; then
                safe_symlink "$src/zshrc" "$HOME/.zshrc"
                return 0
            fi
            ;;

        vim)
            if [[ -f "$src/.vimrc" ]]; then
                safe_symlink "$src/.vimrc" "$HOME/.vimrc"
                return 0
            elif [[ -f "$src/vimrc" ]]; then
                safe_symlink "$src/vimrc" "$HOME/.vimrc"
                return 0
            fi
            ;;

        starship)
            if [[ -f "$src/starship.toml" ]]; then
                ensure_dir "$HOME/.config"
                safe_symlink "$src/starship.toml" "$HOME/.config/starship.toml"
                return 0
            fi
            ;;
    esac

    # 4. Standard XDG or fallback
    # If it's a directory:
    if [[ -d "$src" ]]; then
        # Check if it has leading dot files
        local dotfiles=()
        shopt -s nullglob
        for f in "$src"/.*; do
            local bn="$(basename "$f")"
            [[ "$bn" == "." || "$bn" == ".." || "$bn" == ".target" || "$bn" == ".description" ]] && continue
            dotfiles+=("$f")
        done
        shopt -u nullglob

        if [[ ${#dotfiles[@]} -gt 0 ]]; then
            for f in "${dotfiles[@]}"; do
                safe_symlink "$f" "$HOME/$(basename "$f")"
            done
            return 0
        else
            # Link entire directory to ~/.config/<app>
            ensure_dir "$HOME/.config"
            safe_symlink "$src" "$HOME/.config/$app"
            return $?
        fi
    else
        # It's a single file
        ensure_dir "$HOME/.config"
        safe_symlink "$src" "$HOME/.config/$app"
        return $?
    fi
}

install_configs() {
    local apps=("$@")
    if [[ ${#apps[@]} -eq 0 ]]; then
        log_warn "No configs specified to install."
        return 0
    fi

    log_header "Installing Selected Configurations (${#apps[@]})"
    local count=0
    local failed=0

    for app in "${apps[@]}"; do
        if install_single_config "$app"; then
            count=$((count + 1))
        else
            failed=$((failed + 1))
        fi
    done

    echo ""
    if [[ $failed -eq 0 ]]; then
        log_success "Completed: Installed/updated ${count} config(s) successfully!"
    else
        log_warn "Finished with ${failed} failure(s). ${count} config(s) installed successfully."
    fi
}
