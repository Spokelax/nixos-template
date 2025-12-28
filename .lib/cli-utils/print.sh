#!/usr/bin/env bash

# ==============================================================================
# Print Functions
# ==============================================================================

# Step tracking
_STEP_CURRENT=0
_STEP_TOTAL=0

steps_init() {
    _STEP_TOTAL=$1
    _STEP_CURRENT=0
}

print_header() {
    local title=$1
    local width=60
    local line
    line=$(printf '═%.0s' $(seq 1 $width))

    printf "\n"
    printf "%s%s%s\n" "$C_WHITE_BOLD" "$line" "$C_RESET"
    printf "%s  %s%s\n" "$C_WHITE_BOLD" "$title" "$C_RESET"
    printf "%s%s%s\n" "$C_WHITE_BOLD" "$line" "$C_RESET"
}

print_footer() {
    local success=$1
    local success_msg=${2:-"Completed successfully"}
    local fail_msg=${3:-"Failed"}
    local width=60
    local line
    line=$(printf '═%.0s' $(seq 1 $width))

    printf "\n"
    printf "%s%s%s\n" "$C_DIM" "$line" "$C_RESET"
    if [ "$success" = true ]; then
        printf "%s  %s%s\n" "$C_GREEN_BOLD" "$success_msg" "$C_RESET"
    else
        printf "%s  %s%s\n" "$C_RED_BOLD" "$fail_msg" "$C_RESET"
    fi
    printf "%s%s%s\n" "$C_DIM" "$line" "$C_RESET"
    printf "\n"
}

print_step() {
    local title=$1
    _STEP_CURRENT=$((_STEP_CURRENT + 1))
    printf "\n"
    printf "%s  Step %s/%s: %s%s\n" "$C_CYAN_BOLD" "$_STEP_CURRENT" "$_STEP_TOTAL" "$title" "$C_RESET"
    printf "%s  %s%s\n" "$C_DIM" "$(printf '─%.0s' $(seq 1 40))" "$C_RESET"
}

print_success() {
    local message=$1
    local indent=${2:-4}
    printf "%*s%s%s %s%s\n" "$indent" "" "$C_GREEN" "+" "$C_RESET" "$message"
}

print_warning() {
    local message=$1
    local indent=${2:-4}
    printf "%*s%s%s %s%s%s\n" "$indent" "" "$C_YELLOW" "!" "$C_RESET" "$C_DIM" "$message$C_RESET"
}

print_error() {
    local message=$1
    local indent=${2:-4}
    printf "%*s%s%s %s%s\n" "$indent" "" "$C_RED" "x" "$C_RESET" "$message"
}

print_info() {
    local message=$1
    local indent=${2:-4}
    printf "%*s%s%s%s\n" "$indent" "" "$C_DIM" "$message" "$C_RESET"
}
