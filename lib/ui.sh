#!/usr/bin/env bash
# ==============================================================================
# lib/ui.sh - Interactive Checklist Terminal UI for Config & App Selection
# ==============================================================================

# Determine terminal I/O streams
get_tty_out() {
    if [[ -t 2 ]]; then
        echo "/dev/stderr"
    elif [[ -w /dev/tty ]]; then
        echo "/dev/tty"
    else
        echo "/dev/stderr"
    fi
}

get_tty_in() {
    if [[ -t 0 ]]; then
        echo "/dev/stdin"
    elif [[ -r /dev/tty ]]; then
        echo "/dev/tty"
    else
        echo "/dev/stdin"
    fi
}

# ------------------------------------------------------------------------------
# Fallback numbered selector for non-raw / non-TTY terminals
# ------------------------------------------------------------------------------
fallback_selector() {
    local title="$1"
    shift
    local items=("$@")
    local tty_out="$(get_tty_out)"
    local tty_in="$(get_tty_in)"

    echo "" > "$tty_out"
    echo -e "${COLOR_BOLD}=== ${title} ===${COLOR_RESET}" > "$tty_out"
    echo "Enter numbers separated by space (e.g. '1 3 4'), 'all', or 'q' to cancel:" > "$tty_out"
    echo "" > "$tty_out"

    local idx=1
    for item in "${items[@]}"; do
        echo "  [$idx] $item" > "$tty_out"
        idx=$((idx + 1))
    done
    echo "" > "$tty_out"

    local choice=""
    echo -n "Selection > " > "$tty_out"
    read -r choice < "$tty_in" || choice="q"

    if [[ "$choice" == "q" || "$choice" == "Q" || -z "$choice" ]]; then
        return 1
    fi

    if [[ "$choice" == "all" || "$choice" == "ALL" ]]; then
        for item in "${items[@]}"; do
            echo "$item"
        done
        return 0
    fi

    for num in $choice; do
        if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#items[@]} )); then
            echo "${items[$((num-1))]}"
        fi
    done
    return 0
}

# ------------------------------------------------------------------------------
# Interactive Checklist UI
# ------------------------------------------------------------------------------
run_interactive_checklist() {
    local title="$1"
    local category="$2" # "config" or "app"
    shift 2

    # Parse remaining arguments: items array
    local items=("$@")
    local total_items=${#items[@]}

    if [[ $total_items -eq 0 ]]; then
        log_warn "No ${category} items available to select." >&2
        return 1
    fi

    local tty_out="$(get_tty_out)"
    local tty_in="$(get_tty_in)"

    # Check if we have an interactive terminal
    if [[ ! -t 0 && ! -r /dev/tty ]] || [[ "${TERM:-}" == "dumb" ]]; then
        fallback_selector "$title" "${items[@]}"
        return $?
    fi

    # Initialize descriptions and selections
    local descriptions=()
    local selected=()
    local is_installed=()

    for ((i=0; i<total_items; i++)); do
        local item="${items[i]}"
        local desc=""
        local inst=""

        if [[ "$category" == "config" ]]; then
            desc="$(get_config_description "$item")"
            # Check if predefined
            local is_pre=false
            for pre in "${PREDEFINED_CONFIGS[@]}"; do
                if [[ "$pre" == "$item" ]]; then
                    is_pre=true
                    break
                fi
            done
            if $is_pre; then
                selected+=(1)
            else
                selected+=(0)
            fi
        else
            desc="$(get_app_description "$item")"
            if is_app_installed "$item"; then
                inst="${COLOR_GREEN}[installed]${COLOR_RESET}"
            fi
            # Apps default to unselected unless in PREDEFINED_APPS
            local is_pre=false
            for pre in "${PREDEFINED_APPS[@]:-}"; do
                if [[ "$pre" == "$item" ]]; then
                    is_pre=true
                    break
                fi
            done
            if $is_pre; then
                selected+=(1)
            else
                selected+=(0)
            fi
        fi

        descriptions+=("$desc")
        is_installed+=("$inst")
    done

    # Terminal state setup
    local saved_stty
    saved_stty="$(stty -g < "$tty_in" 2>/dev/null || true)"

    cleanup_ui() {
        if [[ -n "$saved_stty" ]]; then
            stty "$saved_stty" < "$tty_in" 2>/dev/null || true
        fi
        # Re-show cursor
        echo -ne "\033[?25h" > "$tty_out"
    }

    trap cleanup_ui EXIT INT TERM

    # Disable terminal echo and buffering
    stty -echo -icanon min 1 time 0 < "$tty_in" 2>/dev/null || true
    echo -ne "\033[?25l" > "$tty_out" # Hide cursor

    local current=0
    local rendered_lines=0

    render_menu() {
        local buffer=""

        # If not first render, move cursor up
        if (( rendered_lines > 0 )); then
            buffer+="\033[${rendered_lines}A"
        fi

        local lines=0

        # Header box
        buffer+="\033[2K\r${COLOR_BOLD}${COLOR_CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${COLOR_RESET}\n"
        lines=$((lines + 1))

        local title_padded
        title_padded="$(printf " %-74s " "$title")"
        buffer+="\033[2K\r${COLOR_BOLD}${COLOR_CYAN}║${COLOR_RESET}${COLOR_BOLD}${title_padded}${COLOR_CYAN}║${COLOR_RESET}\n"
        lines=$((lines + 1))

        buffer+="\033[2K\r${COLOR_BOLD}${COLOR_CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${COLOR_RESET}\n"
        lines=$((lines + 1))

        # Instructions
        buffer+="\033[2K\r ${COLOR_GRAY}↑/↓ or j/k: Navigate | Space: Toggle | a: Toggle All | Enter: Confirm | q: Quit${COLOR_RESET}\n"
        lines=$((lines + 1))
        buffer+="\033[2K\r\n"
        lines=$((lines + 1))

        # Count selected
        local sel_count=0
        for ((i=0; i<total_items; i++)); do
            if [[ ${selected[i]} -eq 1 ]]; then
                sel_count=$((sel_count + 1))
            fi
        done

        # Render list of items
        for ((i=0; i<total_items; i++)); do
            local marker=" "
            local cursor_prefix="   "
            local color_name="${COLOR_RESET}"
            local checkbox="[ ]"

            if [[ ${selected[i]} -eq 1 ]]; then
                checkbox="${COLOR_GREEN}[✔]${COLOR_RESET}"
            else
                checkbox="${COLOR_GRAY}[ ]${COLOR_RESET}"
            fi

            if (( i == current )); then
                cursor_prefix="${COLOR_CYAN}${COLOR_BOLD} ▸ ${COLOR_RESET}"
                color_name="${COLOR_BOLD}${COLOR_CYAN}"
            else
                cursor_prefix="   "
                color_name="${COLOR_RESET}"
            fi

            local item_str="${items[i]}"
            local desc_str="${descriptions[i]}"
            local inst_str="${is_installed[i]}"

            # Format line
            local line_out
            if [[ -n "$inst_str" ]]; then
                line_out="$(printf "%b%b %-12s %b %s" "$cursor_prefix" "$checkbox" "$item_str" "$inst_str" "${COLOR_GRAY}${desc_str}${COLOR_RESET}")"
            else
                line_out="$(printf "%b%b %-12s %s" "$cursor_prefix" "$checkbox" "$item_str" "${COLOR_GRAY}${desc_str}${COLOR_RESET}")"
            fi

            buffer+="\033[2K\r${line_out}\n"
            lines=$((lines + 1))
        done

        # Footer
        buffer+="\033[2K\r\n"
        lines=$((lines + 1))
        buffer+="\033[2K\r ${COLOR_BOLD}Selected: ${COLOR_GREEN}${sel_count}${COLOR_RESET}${COLOR_BOLD}/${total_items}${COLOR_RESET} items. ${COLOR_DIM}Press ${COLOR_RESET}${COLOR_BOLD}[Enter]${COLOR_RESET}${COLOR_DIM} to proceed, ${COLOR_RESET}${COLOR_BOLD}[q]${COLOR_RESET}${COLOR_DIM} to cancel.${COLOR_RESET}\n"
        lines=$((lines + 1))

        rendered_lines=$lines
        echo -ne "$buffer" > "$tty_out"
    }

    # Main event loop
    render_menu

    while true; do
        local key=""
        local rest=""

        IFS= read -rsn1 key < "$tty_in" || key=""

        if [[ "$key" == $'\x1b' ]]; then
            read -rsn2 -t 0.1 rest < "$tty_in" || rest=""
            key+="$rest"
        fi

        case "$key" in
            # Arrow Up, 'k' or 'K'
            $'\x1b[A'|k|K)
                if (( current > 0 )); then
                    current=$((current - 1))
                else
                    current=$((total_items - 1))
                fi
                render_menu
                ;;

            # Arrow Down, 'j' or 'J'
            $'\x1b[B'|j|J)
                if (( current < total_items - 1 )); then
                    current=$((current + 1))
                else
                    current=0
                fi
                render_menu
                ;;

            # Space - toggle current item
            " ")
                if [[ ${selected[current]} -eq 1 ]]; then
                    selected[current]=0
                else
                    selected[current]=1
                fi
                render_menu
                ;;

            # 'a' or 'A' - toggle all
            a|A)
                # Check if all are currently selected
                local all_sel=true
                for ((i=0; i<total_items; i++)); do
                    if [[ ${selected[i]} -eq 0 ]]; then
                        all_sel=false
                        break
                    fi
                done

                local new_val=1
                $all_sel && new_val=0

                for ((i=0; i<total_items; i++)); do
                    selected[i]=$new_val
                done
                render_menu
                ;;

            # Enter - confirm selection
            ""|$'\r'|$'\n')
                break
                ;;

            # Quit / Cancel
            q|Q|$'\x1b'|$'\x03')
                cleanup_ui
                trap - EXIT INT TERM
                echo -e "\n${COLOR_YELLOW}Selection cancelled by user.${COLOR_RESET}" > "$tty_out"
                return 1
                ;;
        esac
    done

    cleanup_ui
    trap - EXIT INT TERM

    echo "" > "$tty_out"

    # Output selected items to stdout
    local any_selected=false
    for ((i=0; i<total_items; i++)); do
        if [[ ${selected[i]} -eq 1 ]]; then
            echo "${items[i]}"
            any_selected=true
        fi
    done

    $any_selected && return 0
    return 2 # Exit code 2 if confirmed with 0 items selected
}
