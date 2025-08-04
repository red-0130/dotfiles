#!/usr/bin/env bash

if source "$BIN/path_exist.sh"; then return 0; else exit 1; fi

main() {
  log_info nvim "Starting installation..."
  installFzf && installFd && installRipgrep && installLazygit && installNeovim && return 0

  installFzf() {
    log_info fzf "Installing fzf"
    if sudo apt install fzf -y; then
      log_success fzf "Fzf installed successfully."
      return 0
    else
      log_error fzf "There was an error installing Fzf."
      exit 1
    fi
  }

  installFd() {
    log_info "fd-find" "Installing fd-find"
    if sudo apt install fd-find -y; then
      log_success "fd-find" "Successfully installed fs-find."
      return 0
    else
      log_error "fd-find" "There was an error installing fd-find."
      return 1
    fi
  }
  installRipgrep() {
    log_info ripgrep "Installing ripgrep"
    if sudo apt install ripgrep -y; then
      log_success ripgrep "Ripgrep successfully installed."
      return 0
    else
      log_error ripgrep "There was an error installing Ripgrep."
      return 1
    fi
  }
  installLazygit() {
    log_info lazygit "Starting installation..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*') &&
      curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" &&
      tar xf lazygit.tar.gz lazygit
    if sudo install lazygit -D -t /usr/local/bin/; then
      log_success lazygit "Finished installing. Beginning cleanup..."
    else
      log_error lazygit "There was an error installing Lazygit"
      exit 1
    fi
    if rm lazygit*; then
      log_success lazygit "Done"
      return 0
    else
      log_warning lazygit "There was an error removing residual files."
      return 0
    fi
  }
  installNeovim() {
    log_info nvim "Installing Neovim"
    if ! command nvim -v &>/dev/null; then
      curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
      sudo rm -rf /opt/nvim
      sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    else
      log_info nvim "Neovim is already installed"
    fi
    sudo ln -sf "/opt/nvim-linux-x86_64/bin/nvim" "/usr/bin/nvim"
    log_success nvim "Finished installing $(nvim -v | head -n 1)"
    log_info nvim "Cleaning up..."
    rm nvim-linux-x86_64.tar.gz
    log_info nvim "Residual files removed."
    return 0
  }
}
if main; then log_success nvim "Neovim is done installing."; fi
