#!/bin/env bash

#ADD ALIASES HERE
# Replaces ls with eza
if command -v eza &>/dev/null; then
  alias ls="eza --icons"
  alias ll="eza --icons -lhg"
  alias la="eza --icons -alhg"
  alias tree="eza --icons --tree"
fi

# git aliases
if command -v git &>/dev/null; then
  alias commit="git commit -m"
  alias checkout="git checkout"
  alias gitlog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
fi
