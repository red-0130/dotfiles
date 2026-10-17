#!/usr/bin/env bash

main() {
  local APP=rust

  if curl https://sh.rustup.rs -sSf | sh; then
    log -s "Successfully installed Rust+Cargo."
  fi
}

main
