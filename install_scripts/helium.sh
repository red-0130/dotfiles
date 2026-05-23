#!/usr/bin/env bash

main() {
  local APP="Helium Browser"
  log -i "Installing $APP"
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
    elelse
    log -e "There was an error adding the repo APT sources."
    return 1
  fi

  sudo apt update && sudo apt install helium-bin
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
