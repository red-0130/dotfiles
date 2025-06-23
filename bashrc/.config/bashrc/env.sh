# Export if socket exist at HOME directory
if [[ -r "$HOME/.bitwarden-ssh-agent.sock" ]]; then
  export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
fi
# Export if using flatpak
if [[ -r "$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock" ]]; then
  export SSH_AUTH_SOCK="$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock"
fi
# Export if using snap
if [[ -r "$HOME/snap/bitwarden/current/.bitwarden-ssh-agent.sock" ]]; then
  export SSH_AUTH_SOCK="$HOME/snap/bitwarden/current/.bitwarden-ssh-agent.sock"
fi
