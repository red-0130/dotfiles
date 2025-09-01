#!/usr/bin/env bash

main() {

  if curl https://sh.rustup.rs -sSf | sh; then
    log_success rust "Successfully installed Rust+Cargo."
  fi
}

main
