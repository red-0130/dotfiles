#!/bin/env bash

#ADD ALIASES HERE
# Replaces ls with eza
if command -v eza &>/dev/null; then
  alias ls="eza --icons -s type"
  alias ll="eza --icons -alhgs type"
  alias la="eza --icons -ahs type"
  alias tree="eza --icons --tree -as type"
fi

# git aliases
if command -v git &>/dev/null; then
  alias commit="git commit -m"
  alias checkout="git checkout"
  alias gitlog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
fi

# batcat aliases
if command -v batcat &>/dev/null; then
  alias cat="batcat"
fi
