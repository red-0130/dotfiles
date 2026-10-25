# ~/.bash_aliases - Useful command aliases and shortcuts

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"
alias home="cd $HOME"

# Listing
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza --icons -alg --git --group-directories-first"
  alias la="eza --icons -a --group-directories-first"
  alias tree="eza --icons --tree -a --group-directories-first"
else
  alias ls="ls --group-directories-first --color=auto"
  alias ll="ls --group-directories-first --color=auto -al"
  alias la="ls --group-directories-first --color=auto -a"
fi

# Git shortcuts
if command -v git &>/dev/null; then
  alias commit="git commit -m"
  alias checkout="git checkout"
  alias pull='git pull'
  alias push='git push'
  alias addall='git add -A'
  alias status='git status'
  alias gitlog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
fi

# Safety nets
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -I"

# Grep colors
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

# Utilities
alias path='echo -e ${PATH//:/\\n}'
alias reload="source ~/.bashrc"
alias myip="curl -s https://ifconfig.me"

# batcat aliases
if command -v batcat &>/dev/null || command -v bat &>/dev/null; then
  alias cat="batcat"
fi

# apt commands
alias update='sudo apt update'
alias upgrade='sudo apt full-upgrade -y'

# project commands
alias personal="cd $HOME/Projects/personal"
alias playground="cd $HOME/Projects/playground"
! [[ -z ${PROJECT_WORKSPACE+x} ]] && alias workspace="cd $PROJECT_WORKSPACE"

# podman commands
if command -v podman &>/dev/null && command -v fzf &>/dev/null; then
  alias image-rm='podman image rm $(podman image ls | fzf --accept-nth=3)'
  alias container-rm='podman rm $(podman ps -a | fzf --accept-nth=1)'
fi

# coder commands
if command -v coder &>/dev/null; then
  alias cls="coder list --column workspace,status,healthy,outdated"
  alias cstart="coder start"
  alias crm="coder delete"
  alias cmk="coder create"
fi
