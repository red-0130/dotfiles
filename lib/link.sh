#!/usr/bin/env bash
# ==============================================================================
# lib/link.sh - Safe symlink creation with backup support
# ==============================================================================

safe_symlink() {
    local source="$1"
    local target="$2"

    if [[ ! -e "$source" ]]; then
        log_error "Source file does not exist: $source"
        return 1
    fi

    # Expand any ~ in target if present
    target="${target/#\~/$HOME}"

    # Resolve absolute path for source
    local abs_source
    abs_source="$(cd "$(dirname "$source")" && pwd)/$(basename "$source")"

    # Check if target already points to this exact source
    if [[ -L "$target" ]]; then
        local current_target
        current_target="$(readlink "$target")"
        # If relative or absolute, check match
        if [[ "$current_target" == "$abs_source" ]] || [[ "$current_target" == "$source" ]]; then
            log_dim "Already linked: ${target/#$HOME/~} -> ${abs_source}"
            return 0
        fi
    fi

    # Target exists and differs, or broken symlink: back it up
    if [[ -e "$target" || -L "$target" ]]; then
        backup_target "$target" || return 1
    fi

    # Ensure parent directory exists
    ensure_dir "$(dirname "$target")"

    # Create symlink
    if ln -s "$abs_source" "$target"; then
        log_success "Linked: ${target/#$HOME/~} -> ${abs_source/#$HOME/~}"
        return 0
    else
        log_error "Failed to link: $target -> $abs_source"
        return 1
    fi
}
