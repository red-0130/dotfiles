log_info() {
  local -u APP="$1"
  local MESSAGE="$2"
  local -u MESSAGE_TYPE="info"
  echo -e "\e[39;1m[$APP][$MESSAGE_TYPE]:\e[0m $MESSAGE"
}

log_error() {
  local -u APP="$1"
  local MESSAGE="$2"
  local -u MESSAGE_TYPE="error"
  local -r COLOR="\e[31m"
  echo -e "\e[39;1m$COLOR[$APP][$MESSAGE_TYPE]:\e[0m $MESSAGE"
}

log_success() {
  local -u APP="$1"
  local MESSAGE="$2"
  local -u MESSAGE_TYPE="success"
  local -r COLOR="\e[32m"
  echo -e "\e[39;1m$COLOR[$APP][$MESSAGE_TYPE]:\e[0m $MESSAGE"
}

log_warning() {
  local -u APP="$1"
  local MESSAGE="$2"
  local -u MESSAGE_TYPE="warning"
  local -r COLOR="\e[33m"
  echo -e "\e[39;1m$COLOR[$APP][$MESSAGE_TYPE]:\e[0m $MESSAGE"
}
