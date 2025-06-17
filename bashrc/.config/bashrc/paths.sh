#!/bin/env bash

# ADD CUSTOM PATHS HERE
source $HOME/.config/bashrc/lib/create-component.sh
if [[ -z "$SSH_CONNECTION" ]]; then
  source $HOME/.config/bashrc/lib/create-workspace.sh
fi
