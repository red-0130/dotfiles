main() {
    APP="gitconfig"
    log -i "Applying global git config..."

    if ln -sf "$CONFIG/$APP/config/.gitconfig" "$HOME/.gitconfig"; then
        log -s "Global git config applied successfully."
    else
        log -e "Failed to apply global git config."
        return 1
    fi
}
main