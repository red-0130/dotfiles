# ~/.bash_aliases - Useful command aliases and shortcuts

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"

# Listing
if command -v eza >/dev/null 2>&1; then
    alias ls="eza"
    alias ll="eza -la --git"
    alias la="eza -a"
    alias lt="eza --tree"
else
    alias ls="ls --color=auto"
    alias ll="ls -lah --color=auto"
    alias la="ls -A --color=auto"
    alias l="ls -CF --color=auto"
fi

# Git shortcuts
alias g="git"
alias gs="git status"
alias ga="git add"
alias gaa="git add --all"
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit --amend"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gd="git diff"
alias gds="git diff --staged"
alias gp="git push"
alias gpl="git pull"
alias gl="git log --oneline --graph --decorate -n 20"
alias gb="git branch"

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
