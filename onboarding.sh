#!/usr/bin/env bash

# NixOS Template Onboarding Script
# ==============================================================================
# Interactive setup for new hosts
#
# Steps:
#   1. Pre-checks (directory, nixos-generate-config, existing config)
#   2. Configuration (hostname, optional user)
#   3. Hardware configuration
#   4. Create host files
#   5. Apply configuration (optional)
#
# Usage:
#   ./onboarding.sh
# ==============================================================================

set -e

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTS_DIR="$SCRIPT_DIR/hosts"

# ==============================================================================
# Load utilities
# ==============================================================================

source "$SCRIPT_DIR/.lib/cli-utils/colors.sh"
source "$SCRIPT_DIR/.lib/cli-utils/print.sh"
source "$SCRIPT_DIR/.lib/cli-utils/prompts.sh"

# ==============================================================================
# Global state
# ==============================================================================

NEW_HOSTNAME=""
NEW_USERNAME=""
CREATE_USER=false

# ==============================================================================
# Setup functions
# ==============================================================================

check_existing() {
    if [ -f "$HOSTS_DIR/default.nix" ]; then
        print_warning "default.nix exists"
        if ! prompt_yes_no "Overwrite existing configuration?"; then
            print_info "Aborted by user"
            exit 0
        fi
        print_success "Will overwrite existing config"
    else
        print_success "No existing configuration"
    fi
}

generate_hardware_config() {
    print_info "Generating hardware configuration..."

    if nixos-generate-config --show-hardware-config >"$HOSTS_DIR/hardware.nix" 2>/dev/null; then
        print_success "Generated hardware.nix"
    else
        print_error "Failed to generate hardware config"
        return 1
    fi
}

create_default_nix() {
    cat >"$HOSTS_DIR/default.nix" <<EOF
# ============================================================================
# Host Index
# ============================================================================

{ mkHost }:

{
  $NEW_HOSTNAME = mkHost {
    hostname = "$NEW_HOSTNAME";
    system = "x86_64-linux";
    modules = [
      ./config.nix
      ./hardware.nix
    ];
  };
}
EOF
    print_success "Created default.nix"
}

create_config_nix() {
    if [ "$CREATE_USER" = true ] && [ -n "$NEW_USERNAME" ]; then
        cat >"$HOSTS_DIR/config.nix" <<EOF
# ============================================================================
# Host Configuration
# ============================================================================

{ ... }:

{
  # Bootstrap user: default / pwd

  users.users.$NEW_USERNAME = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 ..." ];
  };
}
EOF
    else
        cat >"$HOSTS_DIR/config.nix" <<EOF
# ============================================================================
# Host Configuration
# ============================================================================

{ ... }:

{
  # Bootstrap user: default / pwd

  # users.users.myuser = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ];
  #   openssh.authorizedKeys.keys = [ "ssh-ed25519 ..." ];
  # };
}
EOF
    fi
    print_success "Created config.nix"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    print_header "NixOS Template · Onboarding"
    steps_init 5

    # --------------------------------------------------------------------------
    # Step 1: Pre-checks
    # --------------------------------------------------------------------------
    print_step "Pre-checks"

    if command -v nixos-generate-config &>/dev/null; then
        print_success "nixos-generate-config found"
    else
        print_error "nixos-generate-config not found"
        print_info "Run this script on a NixOS system"
        print_footer false "Setup failed"
        exit 1
    fi

    if [ ! -d "$HOSTS_DIR" ]; then
        mkdir -p "$HOSTS_DIR"
        print_success "Created hosts directory"
    else
        print_success "Hosts directory exists"
    fi

    check_existing

    # --------------------------------------------------------------------------
    # Step 2: Gather information
    # --------------------------------------------------------------------------
    print_step "Configuration"

    # Hostname
    local default_hostname
    default_hostname=$(hostname 2>/dev/null || echo "nixos")
    NEW_HOSTNAME=$(prompt_input "Hostname" "$default_hostname")

    if [ -z "$NEW_HOSTNAME" ]; then
        print_error "Hostname cannot be empty"
        print_footer false "Setup failed"
        exit 1
    fi
    print_success "Hostname: $NEW_HOSTNAME"

    # User creation
    printf "\n"
    if prompt_yes_no "Create a user account?"; then
        CREATE_USER=true
        NEW_USERNAME=$(prompt_input "Username")
        if [ -n "$NEW_USERNAME" ]; then
            print_success "Will create user: $NEW_USERNAME"
        else
            CREATE_USER=false
            print_info "Skipped (empty username)"
        fi
    else
        print_info "Using bootstrap user only (default/pwd)"
    fi

    # --------------------------------------------------------------------------
    # Step 3: Generate hardware config
    # --------------------------------------------------------------------------
    print_step "Hardware Configuration"

    if ! generate_hardware_config; then
        print_footer false "Setup failed"
        exit 1
    fi

    # --------------------------------------------------------------------------
    # Step 4: Create host files
    # --------------------------------------------------------------------------
    print_step "Host Files"

    create_default_nix
    create_config_nix

    # --------------------------------------------------------------------------
    # Step 5: Apply configuration
    # --------------------------------------------------------------------------
    print_step "Apply Configuration"

    printf "\n"
    if prompt_yes_no "Apply configuration now?"; then
        print_info "Rebuilding system (this may take a few minutes)..."
        printf "\n"

        if sudo nixos-rebuild switch --flake "$SCRIPT_DIR" --experimental-features "nix-command flakes"; then
            print_success "System configured successfully"
            print_footer true "Setup completed"

            printf "    %sNext steps:%s\n" "$C_WHITE_BOLD" "$C_RESET"
            printf "    %s1.%s Reboot if kernel was updated\n" "$C_DIM" "$C_RESET"
            printf "    %s2.%s Login as your user\n" "$C_DIM" "$C_RESET"
            printf "    %s3.%s Future rebuilds: %srebuild%s\n" "$C_DIM" "$C_RESET" "$C_WHITE_BOLD" "$C_RESET"
            printf "\n"
        else
            print_error "Rebuild failed"
            print_footer false "Setup incomplete"

            printf "    %sTo retry:%s\n" "$C_WHITE_BOLD" "$C_RESET"
            printf "    %ssudo nixos-rebuild switch --flake . --experimental-features \"nix-command flakes\"%s\n" "$C_DIM" "$C_RESET"
            printf "\n"
            exit 1
        fi
    else
        print_info "Skipped - configuration not applied"
        print_footer true "Files created successfully"

        printf "    %sTo apply manually:%s\n" "$C_WHITE_BOLD" "$C_RESET"
        printf "    %s1.%s Review hosts/config.nix\n" "$C_DIM" "$C_RESET"
        printf "    %s2.%s Run: %ssudo nixos-rebuild switch --flake . --experimental-features \"nix-command flakes\"%s\n" "$C_DIM" "$C_RESET" "$C_WHITE_BOLD" "$C_RESET"
        printf "    %s3.%s Future rebuilds: %srebuild%s\n" "$C_DIM" "$C_RESET" "$C_WHITE_BOLD" "$C_RESET"
        printf "\n"
    fi
}

main "$@"
