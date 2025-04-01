#!/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

main() {
  checkApt
  if installWhiptail; then
    startInteractive
  fi
}

startInteractive() {
  echo "Starting interactve script"
  whiptail --title "DOTFILES Setup" --separate-output \
    --checklist "Select Application/Config to apply" 20 60 10 \
    "nvim" "Install Neovim and apply configuration" OFF \
    "superfile" "Superfile config" OFF \
    "bashrc" "bashrc config" OFF \
    3>&1 1>&2 2>&3 |
    while read CHOICE; do
      CONFIG_MAIN="$SCRIPT_DIR/$CHOICE"
      CONFIG_LOCAL="$HOME/.config/$CHOICE"

      if [[ "$CHOICE" = "bashrc" ]]; then
        echo "bashrc configuration require the installation of 'ohmybash'."
        echo "Installing Oh-My-Bash"
        installOhMyBash
        transferBashrc
      fi

      if [[ "$CHOICE" = "fonts" ]]; then
        echo "Installing fonts"
        fc-cache -v $HOME/.local/share/fonts
      fi

      if [[ "$CHOICE" = "nvim" ]]; then
        installLazyvimDependencies
        installNeovim
        applyConfig "$CONFIG_MAIN/.config/$CHOICE" "$CONFIG_LOCAL"
      fi

      if [[ "$CHOICE" = "superfile" ]]; then
        installSpf
      fi

      if [[ "$CHOICE" = "ssh" ]]; then
        appendSshConfig

      fi

    done

  echo "Finished installing config"

}

installSpf() {
  echo "Installing Superfile"
  bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"
  if [[ -d "$HOME/.config/superfile" ]]; then
    echo "Making backup of local config"
    makeBackup "$HOME/.config/superfile"
  fi
  if [[ ! -d $HOME/.config ]]; then
    mkdir "$HOME/.config"
  fi
  echo "Importing config"
  ln -s "$SCRIPT_DIR/superfile/.config/superfile" "$HOME/.config/superfile"
  if ! grep "source $HOME/.config/superfile/cd_on_quit.sh" "$HOME/.bashrc"; then
    echo "Importing cd_on_quit script from config"
    echo "source $HOME/.config/superfile/cd_on_quit.sh" >>"$HOME/.bashrc"
  fi
  echo "Done."
}

checkApt() {
  if ! sudo dpkg -s apt &>/dev/null; then
    echo "ERROR: APT is not installed."
    exit 0
  else
    echo "Updating apt repositories"
    sudo apt update
    echo "Proceeding with system upgrade."
    sudo apt full-upgrade -y
  fi
}

installWhiptail() {
  if ! sudo dpkg -s whiptail &>/dev/null; then
    echo "Whiptail is not installed. Starting installation now."
    sudo apt install whiptail -y
    echo "Done."
  else
    echo "Whiptail is installed. Proceeding to interactive script."
  fi
}

installOhMyBash() {
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
}

transferBashrc() {
  echo "Making backup of local bashrc and profile config"
  makeBackup "$HOME/.bashrc"
  makeBackup "$HOME/.profile"
  echo "Transferring bashrc and profile config"
  ln -s "$SCRIPT_DIR/bashrc/.bashrc" "$HOME/.bashrc"
  ln -s "$SCRIPT_DIR/bashrc/.profile" "$HOME/.profile"
  echo "Transfer complete."
  echo "You may need to restart the terminal for config to apply"
}

applyConfig() {
  # @param {directory to be applied} $1
  # @param {directory on local} $2
  echo "Applying config from repo..."
  CONFIG="$1"
  CONFIG_DES="$2"
  if [[ -e "$CONFIG_DES" ]]; then
    makeBackup $CONFIG_DES
  fi
  if [[ ! -d "$HOME/.config" ]]; then
    mkdir "$HOME/.config"
  fi
  ln -sf "$CONFIG" "$CONFIG_DES"
  echo "Finished applying config."
}

makeBackup() {
  # @param {directory/file} $1
  BACKUP_DIR="$HOME/.config.bak"
  EXISTING_CONFIG=$1
  if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "Backup directory not detected."
    echo "Creating backup directory now."
    mkdir "$BACKUP_DIR"
  fi
  echo "Moving existing configuration to backup directory($BACKUP_DIR)"
  mv "$EXISTING_CONFIG" "$BACKUP_DIR"
}

appendSshConfig() {
  INCLUDES="Include "$HOME"/.config/ssh/config"
  FILE="$HOME/.ssh/config"
  if [[ ! -z "$(grep "$INCLUDES" "$FILE")" ]]; then
    echo -e "$INCLUDES\n$(cat $FILE)" >"$FILE"
  fi
}

installNeovim() {
  if ! nvim -v &>/dev/null; then
    echo "Installing Neovim"
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    echo "Finished installing $(nvim -v | head -n 1)"
    echo "Cleaning up..."
    rm nvim-linux-x86_64.tar.gz
    echo "Done."
  else
    echo "Neovim is already installed"
  fi
  NVIM_PATH="export PATH=\"$PATH:/opt/nvim-linux-x86_64/bin\""
  if ! grep -q "$NVIM_PATH" "$HOME/.bashrc"; then
    echo "export PATH=\"$PATH:/opt/nvim-linux-x86_64/bin\"" >>"$HOME/.bashrc"
  fi
}

installLazyvimDependencies() {
  installLazygit
  installFzf
  installRipgrep
  installFd
}

installLazygit() {
  echo "Installing Lazygit"
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit -D -t /usr/local/bin/
  echo "Finished installing. Beginning cleanup..."
  rm lazygit*
  echo "Done."
}

installFzf() {
  echo "Installing fzf"
  sudo apt install fzf
  echo "Done."
}

installRipgrep() {
  echo "Installing Ripgrep"
  sudo apt install ripgrep
  echo "Done."
}

installFd() {
  echo "Installing fd-find"
  sudo apt install fd-find
  echo "Done."
}

main "$@"
exit
