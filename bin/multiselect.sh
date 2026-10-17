#!/usr/bin/env bash

# Pure-Bash interactive multiselect menu (checklist)
# Usage: multiselect "Title" "Prompt" "key1" "desc1" "status1" "key2" "desc2" "status2" ...
# Outputs selected keys to stdout, one per line. Returns 0 on success, 1 on cancel/error.
multiselect() {
  (
    local title="$1"
    local prompt="$2"
    shift 2

    # Parse triplets: (value, description, status)
    local options=()
    local descriptions=()
    local selected=()
    local num_options=0

    while (($# >= 3)); do
      options[num_options]="$1"
      descriptions[num_options]="$2"
      if [[ "$3" == "ON" ]]; then
        selected[num_options]="true"
      else
        selected[num_options]="false"
      fi
      num_options=$((num_options + 1))
      shift 3
    done

    if ((num_options == 0)); then
      echo "Error: No options provided to multiselect." >&2
      exit 1
    fi

    local current_index=0
    local old_settings=$(stty -g)
    local normal_exit=0
    local error_msg=""

    # Ensure cursor, alternate screen, and terminal settings are restored on any exit
    cleanup() {
      stty "$old_settings"
      tput cnorm >&2 # Show cursor
      tput rmcup >&2 # Restore original screen buffer
      if ((normal_exit == 0)); then
        exit 1
      fi
    }
    trap cleanup EXIT INT TERM

    tput smcup >&2 # Switch to alternate screen buffer
    tput clear >&2 # Clear alternate screen
    tput civis >&2 # Hide cursor

    # Main interactive loop
    local key
    while true; do
      # Move cursor to top-left of alternate screen
      tput cup 0 0 >&2

      # Render header (gorgeous Unicode box-drawing format)
      echo -e "\e[34;1m┌──────────────────────────────────────────────────┐\e[0m" >&2
      local title_len=${#title}
      local pad=$(( (50 - title_len) / 2 ))
      local pad_str=""
      for ((k=0; k<pad; k++)); do pad_str+=" "; done
      local right_pad=$(( 50 - title_len - pad ))
      local right_pad_str=""
      for ((k=0; k<right_pad; k++)); do right_pad_str+=" "; done
      echo -e "\e[34;1m│\e[0m${pad_str}\e[1;37m${title}\e[0m${right_pad_str}\e[34;1m│\e[0m" >&2
      echo -e "\e[34;1m└──────────────────────────────────────────────────┘\e[0m" >&2
      echo -e "\e[1m$prompt\e[0m" >&2
      echo -e "\e[90m(Arrows/j/k: Navigate, Space: Toggle, Enter: Confirm, Esc/q: Cancel)\e[0m" >&2
      echo -e "" >&2

      # Get current terminal height dynamically
      local term_rows
      term_rows=$(tput lines 2>/dev/null || echo 24)
      
      # Determine available height for option items
      local overhead=10
      local max_visible=$((term_rows - overhead))
      if ((max_visible < 3)); then
        max_visible=3
      fi

      # Calculate sliding window for viewport scrolling
      local start_idx=0
      local show_scroll=0
      if ((num_options <= max_visible)); then
        start_idx=0
        max_visible=$num_options
        show_scroll=0
      else
        show_scroll=1
        start_idx=$((current_index - max_visible / 2))
        if ((start_idx < 0)); then
          start_idx=0
        elif ((start_idx > num_options - max_visible)); then
          start_idx=$((num_options - max_visible))
        fi
      fi

      # Draw top scroll indicator
      if ((show_scroll)); then
        if ((start_idx > 0)); then
          echo -e "    \e[90m▲ ... more options above ...\e[0m\e[K" >&2
        else
          echo -e "\e[K" >&2
        fi
      fi

      # Draw visible options
      local i draw_count=0
      for ((i=start_idx; i<num_options && draw_count<max_visible; i++)); do
        local checkbox="[ ]"
        if [[ "${selected[i]}" == "true" ]]; then
          checkbox="[\e[32;1m✔\e[0m]"
        fi

        if ((i == current_index)); then
          # Highlight active option with bold cyan and cursor pointer
          echo -e " \e[36;1m➔\e[0m  $checkbox \e[36;1m${options[i]}\e[0m - \e[37m${descriptions[i]}\e[0m\e[K" >&2
        else
          echo -e "    $checkbox \e[37m${options[i]}\e[0m - \e[90m${descriptions[i]}\e[0m\e[K" >&2
        fi
        draw_count=$((draw_count + 1))
      done

      # Draw bottom scroll indicator
      if ((show_scroll)); then
        if ((start_idx + max_visible < num_options)); then
          echo -e "    \e[90m▼ ... more options below ...\e[0m\e[K" >&2
        else
          echo -e "\e[K" >&2
        fi
      fi

      echo -e "" >&2
      # Draw error/warning message if any and clear to end of screen to erase leftovers
      if [[ -n "$error_msg" ]]; then
        echo -e "\e[31;1m$error_msg\e[0m\e[J" >&2
      else
        echo -e "\e[J" >&2
      fi

      # Read character from FD 2 (standard error, guaranteed to be the terminal)
      IFS= read -r -s -n 1 key <&2

      # Clear error message on any keypress
      error_msg=""

      if [[ "$key" == $'\e' ]]; then
        # Check if it is an arrow escape sequence
        IFS= read -r -s -n 2 -t 0.1 next_chars <&2
        if [[ "$next_chars" == "[A" ]]; then
          current_index=$(( (current_index - 1 + num_options) % num_options ))
        elif [[ "$next_chars" == "[B" ]]; then
          current_index=$(( (current_index + 1) % num_options ))
        elif [[ -z "$next_chars" ]]; then
          # Esc key pressed
          exit 1
        fi
      elif [[ "$key" == "k" || "$key" == "K" ]]; then
        # Vim up key
        current_index=$(( (current_index - 1 + num_options) % num_options ))
      elif [[ "$key" == "j" || "$key" == "J" ]]; then
        # Vim down key
        current_index=$(( (current_index + 1) % num_options ))
      elif [[ "$key" == " " ]]; then
        # Spacebar to toggle selection
        if [[ "${selected[current_index]}" == "true" ]]; then
          selected[current_index]="false"
        else
          selected[current_index]="true"
        fi
      elif [[ "$key" == "" ]]; then
        # Enter key: check if at least one option is selected
        local selected_count=0
        for ((i=0; i<num_options; i++)); do
          if [[ "${selected[i]}" == "true" ]]; then
            selected_count=$((selected_count + 1))
          fi
        done

        if ((selected_count > 0)); then
          break
        else
          error_msg="⚠️  Error: No items selected. Select with Spacebar, or press Esc/q to cancel."
        fi
      elif [[ "$key" == "q" || "$key" == "Q" ]]; then
        # Q key to cancel
        exit 1
      fi
    done

    # Clean up and output selected items
    normal_exit=1
    stty "$old_settings"
    tput cnorm >&2 # Show cursor
    tput rmcup >&2 # Restore original screen buffer

    for ((i=0; i<num_options; i++)); do
      if [[ "${selected[i]}" == "true" ]]; then
        echo "${options[i]}"
      fi
    done
  )
}
