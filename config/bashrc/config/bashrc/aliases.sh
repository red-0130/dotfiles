#!/bin/env bash

#ADD ALIASES HERE
# Replaces ls with eza
if command -v eza &>/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza --icons -alhg --group-directories-first"
  alias la="eza --icons -ah --group-directories-first"
  alias tree="eza --icons --tree -a --group-directories-first"
else
  alias ls="ls --group-directories-first --color=auto"
  alias ll="ls --group-directories-first --color=auto -al"
  alias la="ls --group-directories-first --color=auto -a"
fi

# git aliases
if command -v git &>/dev/null; then
  alias commit="git commit -m"
  alias checkout="git checkout"
  alias pull='git pull'
  alias push='git push'
  alias addall='git add -A'
  alias status='git status'
  alias gitlog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
fi

# batcat aliases
if command -v batcat &>/dev/null; then
  alias cat="batcat"
fi

# cd commands
alias ..='cd ..'
alias ...='cd ../..'
alias home="cd $HOME"

# apt commands
alias update='sudo apt update'
alias upgrade='sudo apt full-upgrade -y'

# project commands
alias personal="cd $HOME/Codespace/projects/personal"
alias playground="cd $HOME/Codespace/projects/playground"