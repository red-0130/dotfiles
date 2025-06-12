message() {
  local NOCOLOR='\e[0m'
  local COLOR="$NOCOLOR"
  local GREEN='\e[32m'
  local BLUE='\e[34m'
  local RED='\e[31m'
  local YELLOW='\e[33m'
  local BOLD='\e[39;1m'
  local RESET='\e[0m'
  local TYPE="$1"
  local APPLICATION="$BOLD[$2]$RESET"
  local MESSAGE=$3
  local MESSAGE_TYPE=""

  case "$TYPE" in
  "success")
    COLOR=$GREEN
    MESSAGE_TYPE="[SUCCESS]"
    ;;
  "error")
    COLOR=$RED
    MESSAGE_TYPE="[ERROR]"
    ;;
  "warning")
    COLOR=$YELLOW
    MESSAGE_TYPE="[WARNING]"
    ;;
  *)
    COLOR=$NOCOLOR
    MESSAGE_TYPE="[INFO]"
    ;;
  esac

  echo -e "$COLOR$APPLICATION$COLOR$MESSAGE_TYPE$RESET: $MESSAGE"

}
