#!/usr/bin/env bash

main() {
  local APP="Helium Browser"
  log -i "Installing $APP"

  if command -v apt &>/dev/null; then
    installDebian && return 0
  fi

  if command -v dnf &>/dev/null; then
    installRpm && return 0
  fi

  # TODO: Add AppImage installer
}

installRpm() {
  log -i "Installing using DNF"
  sudo dnf copr enable imput/helium && sudo dnf install helium-bin && log -s "Successfully installed Helium Browser" || log -e "There was an error installing $APP"
}

installDebian() {

  log -i "Installing using APT"
  log -i "Installing pubkey..."
  if addSigningPubKey; then
    log -s "Pubkey installed."
  else
    log -e "Unable to install public key"
    return 1

  fi

  log -i "Adding Helium Browser apt repo"
  if addHeliumRepo; then
    log -s "Helium Browser repo added."
  else
    log -e "There was an error adding the repo APT sources."
    return 1
  fi

  sudo apt update && sudo apt install helium-bin && log -s "Successfully installed Helium Browser" || log -e "There was an error installing $APP"
}

addSigningPubKey() {
  curl -fsSL https://raw.githubusercontent.com/imputnet/helium-linux/main/pubkey.asc | sudo gpg --dearmor -o /usr/share/keyrings/helium.gpg
  if [[ ${PIPESTATUS[1]} -ne 0 ]]; then
    return 1
  fi
  return 0
}

addHeliumRepo() {
  echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/helium.gpg] https://pkg.helium.computer/deb stable main" | sudo tee /etc/apt/sources.list.d/helium.list
  if [[ ${PIPESTATUS[1]} -ne 0 ]]; then
    return 1
  fi
  return 0
}

main
