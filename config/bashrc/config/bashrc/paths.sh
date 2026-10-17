#!/bin/env bash

# ADD CUSTOM PATHS HERE
source $HOME/.config/bashrc/lib/create-component.sh
source $HOME/.config/bashrc/lib/workspacectl.sh
source $HOME/.config/bashrc/lib/onsubnet.sh
source $HOME/.config/bashrc/lib/cd-on-quit.sh
source $HOME/.config/bashrc/lib/magic-shell.sh

[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"