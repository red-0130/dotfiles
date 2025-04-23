#!/bin/env bash

#ADD ALIASES HERE
# Replaces ls with eza
if command -v eza &>/dev/null; then
  alias ls="eza --icons"
  alias ll="eza --icons -lhg"
  alias la="eza --icons -alhg"
  alias tree="eza --icons --tree"
fi
