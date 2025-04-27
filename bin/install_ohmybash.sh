#!/bin/env bash
main() {
  if [[ ! -e "$HOME/.oh-my-bash" ]]; then
    installOhMyBash
    changeTheme
    source $HOME/.bashrc
  fi
}
installOhMyBash() {
  echo "Installing Oh-My-Bash"
  if bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"; then
    echo "Finished installing oh-my-bash"
  else
    echo "There was error while installing Oh-My-Bash"
  fi
}
changeTheme() {
  BASHRC="$HOME/.bashrc"
  echo "Changing oh-my-bash theme"
  sed -i '/OSH_THEME/c\OSH_THEME=\"ht\"' "$BASHRC"
}

main "$@"
