# get current branch in git repo
function parse_git_branch() {
  local branch stat
  branch=$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/' || true)
  if [[ -n "$branch" ]]; then
    stat=$(parse_git_dirty)
    echo " [${branch}${stat}]"
  else
    echo ""
  fi
}

function parse_git_dirty {
  local line xy ch
  local dirty=0 untracked=0 ahead=0 newfile=0 renamed=0 deleted=0
  local bits=''

  while IFS= read -r line; do
    if [[ "$line" == "## "* ]]; then
      [[ "$line" == *"["*ahead\ [0-9]*"]" ]] && ahead=1
      continue
    fi
    xy="${line:0:2}"
    if [[ "$xy" == "??" ]]; then
      untracked=1
      continue
    fi
    for ch in "${xy:0:1}" "${xy:1:1}"; do
      case "$ch" in
        M) dirty=1 ;;
        A) newfile=1 ;;
        R) renamed=1 ;;
        D) deleted=1 ;;
      esac
    done
  done < <(git status --porcelain=v1 --branch 2>/dev/null)

  [[ "$renamed" -eq 1 ]] && bits=">${bits}"
  [[ "$ahead" -eq 1 ]] && bits="*${bits}"
  [[ "$newfile" -eq 1 ]] && bits="+${bits}"
  [[ "$untracked" -eq 1 ]] && bits="?${bits}"
  [[ "$deleted" -eq 1 ]] && bits="x${bits}"
  [[ "$dirty" -eq 1 ]] && bits="!${bits}"
  if [[ -n "${bits}" ]]; then
    echo " ${bits}"
  else
    echo ""
  fi
}

function test_container() {
  [[ -f "/.dockerenv" ]] || [[ -n "${CONTAINER:-}" ]] && echo "[$(id -un)@$HOSTNAME]"
}

function get_short_path() {
  local path=$(pwd)
  # Replace home directory with ~
  if [[ "$path" == "$HOME"* ]]; then
    path="~${path#$HOME}"
  fi
  local depth=$(echo "$path" | tr '/' '\n' | wc -l)
  if [ $depth -le 2 ]; then
    echo "$path"
  else
    echo "$path" | sed -E 's|.*/([^/]+/[^/]+)$|\1|'
  fi
}

export PS1="\[\e[36m\]\`test_container\`\[\e[m\] \[\e[34m\]\`get_short_path\`\[\e[m\]\[\e[32m\]\`parse_git_branch\` \[\e[m\]\[\e[32m\]➜\[\e[m\] "
