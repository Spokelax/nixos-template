#!/usr/bin/env bash

# ==============================================================================
# Terminal Colors (tput for compatibility)
# ==============================================================================

if [[ -t 1 ]] && command -v tput &>/dev/null && [[ $(tput colors 2>/dev/null) -ge 8 ]]; then
    C_RESET=$(tput sgr0)
    C_BOLD=$(tput bold)
    C_DIM=$(tput setaf 8)
    C_GREEN=$(tput setaf 2)
    C_GREEN_BOLD=$(tput bold)$(tput setaf 2)
    C_YELLOW=$(tput setaf 3)
    C_YELLOW_BOLD=$(tput bold)$(tput setaf 3)
    C_RED=$(tput setaf 1)
    C_RED_BOLD=$(tput bold)$(tput setaf 1)
    C_WHITE_BOLD=$(tput bold)$(tput setaf 7)
    C_CYAN=$(tput setaf 6)
    C_CYAN_BOLD=$(tput bold)$(tput setaf 6)
    T_CLEAR_EOL=$(tput el)
    T_CUB="cub"
else
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    C_GREEN=""
    C_GREEN_BOLD=""
    C_YELLOW=""
    C_YELLOW_BOLD=""
    C_RED=""
    C_RED_BOLD=""
    C_WHITE_BOLD=""
    C_CYAN=""
    C_CYAN_BOLD=""
    T_CLEAR_EOL=""
    T_CUB=""
fi
