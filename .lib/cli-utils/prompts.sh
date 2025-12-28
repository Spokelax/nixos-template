#!/usr/bin/env bash

# ==============================================================================
# Prompt Functions
# ==============================================================================

prompt_input() {
    local prompt=$1
    local default=$2
    local result=""
    local char
    local default_len=${#default}
    local has_default=false
    [[ -n "$default" ]] && has_default=true

    # Print prompt
    printf "    %s: " "$prompt" >/dev/tty

    # Show dimmed default as placeholder (if any)
    if [[ "$has_default" = true ]]; then
        printf "%s%s%s" "$C_DIM" "$default" "$C_RESET" >/dev/tty
        if [[ -n "$T_CUB" ]]; then
            tput cub "$default_len" >/dev/tty
        fi
    fi

    # Read character by character from tty
    while IFS= read -r -s -n1 char </dev/tty; do
        # Enter pressed (empty char)
        if [[ -z "$char" ]]; then
            break
        fi
        # Backspace
        if [[ "$char" == $'\x7f' ]] || [[ "$char" == $'\b' ]]; then
            if [[ -n "$result" ]]; then
                result="${result%?}"
                printf "\b \b" >/dev/tty
                # If cleared completely, restore dimmed placeholder
                if [[ -z "$result" ]] && [[ "$has_default" = true ]]; then
                    printf "%s%s%s" "$C_DIM" "$default" "$C_RESET" >/dev/tty
                    if [[ -n "$T_CUB" ]]; then
                        tput cub "$default_len" >/dev/tty
                    fi
                fi
            fi
            continue
        fi
        # First character - clear the dimmed placeholder
        if [[ -z "$result" ]] && [[ "$has_default" = true ]]; then
            printf "%s" "$T_CLEAR_EOL" >/dev/tty
        fi
        result+="$char"
        printf "%s" "$char" >/dev/tty
    done

    printf "\n" >/dev/tty

    if [ -z "$result" ]; then
        result="$default"
    fi
    echo "$result"
}

prompt_yes_no() {
    local prompt=$1
    local default=${2:-n}
    local char

    # Show prompt with y/n hint
    if [ "$default" = "y" ]; then
        printf "    %s %s(Y/n)%s " "$prompt" "$C_DIM" "$C_RESET" >/dev/tty
    else
        printf "    %s %s(y/N)%s " "$prompt" "$C_DIM" "$C_RESET" >/dev/tty
    fi

    # Single keypress
    while IFS= read -r -s -n1 char </dev/tty; do
        case "$char" in
            [Yy])
                printf "yes\n" >/dev/tty
                return 0
                ;;
            [Nn])
                printf "no\n" >/dev/tty
                return 1
                ;;
            "")  # Enter - use default
                if [ "$default" = "y" ]; then
                    printf "yes\n" >/dev/tty
                    return 0
                else
                    printf "no\n" >/dev/tty
                    return 1
                fi
                ;;
        esac
    done
}
