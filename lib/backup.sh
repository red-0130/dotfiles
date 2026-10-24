#!/usr/bin/env bash
# ==============================================================================
# lib/backup.sh - Safe backup utility for dotfiles
# ==============================================================================

# Session backup directory initialized on first backup
CURRENT_BACKUP_DIR=""

init_backup_session() {
    if [[ -z "$CURRENT_BACKUP_DIR" ]]; then
        local base_backup="${DOTFILES_BACKUP_DIR:-$HOME/.dotfiles_backup}"
        local timestamp
        timestamp="$(date +%Y%m%d_%H%M%S)"
        CURRENT_BACKUP_DIR="${base_backup}/${timestamp}"
    fi
}

backup_target() {
    local target="$1"

    # If target doesn't exist (and is not a broken symlink), no backup needed
    if [[ ! -e "$target" && ! -L "$target" ]]; then
        return 0
    fi

    init_backup_session
    ensure_dir "$CURRENT_BACKUP_DIR"

    # Compute backup filename relative to HOME or sanitized path
    local rel_name
    if [[ "$target" == "$HOME/"* ]]; then
        rel_name="${target#"$HOME/"}"
    else
        rel_name="$(basename "$target")"
    fi

    # Replace / with _ if saving to a single level or recreate subdirs
    local dest_dir
    dest_dir="${CURRENT_BACKUP_DIR}/$(dirname "$rel_name")"
    ensure_dir "$dest_dir"

    local dest_file="${CURRENT_BACKUP_DIR}/${rel_name}"

    if mv "$target" "$dest_file"; then
        log_info "Backed up existing $(basename "$target") to ${dest_file}"
        return 0
    else
        log_error "Failed to backup $target to $dest_file"
        return 1
    fi
}
