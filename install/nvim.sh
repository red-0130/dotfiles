#!/usr/bin/env bash

if ! source "$BIN/path_exist.sh"; then exit 1; fi

main() {

  installFzf() {
    log_info fzf "Installing fzf..."
    log_info fzf "Downloading install files from repo..."
    rm -rf /tmp/fzf
    if git clone --depth 1 https://github.com/junegunn/fzf.git /tmp/fzf; then
      log_info fzf "Files downloaded /tmp/fzf. Starting installation now."
    else
      log_error fzf "Install files could not be downloaded."
      return 1
    fi

    if /tmp/fzf/install --all; then
      log_success fzf "Successfully installed."
      return 0
    else
      log_error fzf "There was an error installing."
      return 1
    fi
  }

  installFd() {
    if command -v fdfind &>/dev/null; then
      log_warning "fd-find" "FD-FIND is already installed."
      return 0
    fi

    log_info "fd-find" "Installing fd-find"
    rm -rf /tmp/fd

    local VERSION=$(curl -sL "https://api.github.com/repos/sharkdp/fd/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    local FILE="fd-musl_${VERSION}_amd64.deb"

    log_info "fd-find" "Downloading install files from repo..."
    if curl --create-dirs \
      -sLO --output-dir /tmp/fd/ "https://github.com/sharkdp/fd/releases/download/v$VERSION/$FILE"; then
      log_info "fd-find" "Files downloaded. Starting installation..."
    else
      log_error "fd-find" "Install files could not be downloaded."
      return 1
    fi

    if sudo dpkg -i /tmp/fd/$FILE; then
      log_success "fd-find" "Successfully installed."
      return 0
    else
      log_error "fd-find" "There was an error installing."
      return 1
    fi

  }
  installRipgrep() {
    log_info ripgrep "Installing ripgrep"
    rm -rf /tmp/ripgrep
    local RIPGREP_VERSION=$(curl -s "https://api.github.com/repos/BurntSushi/ripgrep/releases/latest" | grep "tag_name" | cut -d '"' -f 4)
    local FILE="ripgrep_$RIPGREP_VERSION-1_amd64.deb"

    log_info ripgrep "Downloading install files from repo..."
    if curl --create-dirs \
      -sLO --output-dir /tmp/ripgrep/ "https://github.com/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/$FILE"; then
      log_info ripgrep "Files downloaded. Starting installation..."
    else
      log_error ripgrep "Install files could not be downloaded."
      return 1
    fi

    if sudo dpkg -i /tmp/ripgrep/$FILE; then
      log_success ripgrep "Successfully installed."
      return 0
    else
      log_error ripgrep "There was an error installing."
      return 1
    fi
  }

  installLazygit() {
    log_info lazygit "Starting installation..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*') &&
      curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_$LAZYGIT_VERSION_Linux_x86_64.tar.gz" &&
      tar xf lazygit.tar.gz lazygit
    if sudo install lazygit -D -t /usr/local/bin/; then
      log_success lazygit "Finished installing. Beginning cleanup..."
    else
      log_error lazygit "There was an error installing Lazygit"
      return 1
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

  log_info nvim "Starting installation..."
  installFzf && installFd && installRipgrep && installLazygit && installNeovim && return 0
}

if main; then log_success nvim "Neovim is done installing."; fi
