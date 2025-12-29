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
NEW_SSH_KEY=""
NEW_PASSWORD_HASH=""
AUTH_METHOD=""  # "password" or "sshkey"
REPLACE_DEFAULT_USER=false
DISABLE_PASSWORD_AUTH=false

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
  "$NEW_HOSTNAME" = mkHost {
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
    if [ "$REPLACE_DEFAULT_USER" = true ]; then
        # Build user config based on auth method
        local user_auth_config=""
        if [ "$AUTH_METHOD" = "sshkey" ]; then
            user_auth_config="openssh.authorizedKeys.keys = [ \"$NEW_SSH_KEY\" ];"
        else
            user_auth_config="hashedPassword = \"$NEW_PASSWORD_HASH\";"
        fi

        # Build password auth config
        local ssh_password_config=""
        if [ "$DISABLE_PASSWORD_AUTH" = true ]; then
            ssh_password_config="
  # Disable password authentication (SSH key only)
  services.openssh.settings.PasswordAuthentication = false;"
        fi

        cat >"$HOSTS_DIR/config.nix" <<EOF
# ============================================================================
# Host Configuration
# ============================================================================

{ ... }:

{
  # Disable bootstrap user
  users.users.default = {
    isNormalUser = false;
    hashedPassword = "!";  # Locked account
  };

  # Primary user
  users.users.$NEW_USERNAME = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    $user_auth_config
  };$ssh_password_config
}
EOF
    else
        cat >"$HOSTS_DIR/config.nix" <<EOF
# ============================================================================
# Host Configuration
# ============================================================================

{ ... }:

{
  # Using bootstrap user: default / pwd
  # Replace with your own user when ready:
  #
  # users.users.default = {
  #   isNormalUser = false;
  #   hashedPassword = "!";
  # };
  #
  # users.users.myuser = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ];
  #   hashedPassword = "...";  # Generate with: mkpasswd -m sha-512
  #   # or use SSH key:
  #   # openssh.authorizedKeys.keys = [ "ssh-ed25519 ..." ];
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

    # User setup
    printf "\n"
    if prompt_yes_no "Replace default user with your own?"; then
        REPLACE_DEFAULT_USER=true

        # 3.1 Username
        NEW_USERNAME=$(prompt_input "Username")
        if [ -z "$NEW_USERNAME" ]; then
            print_error "Username cannot be empty"
            print_footer false "Setup failed"
            exit 1
        fi
        print_success "Username: $NEW_USERNAME"

        # 3.2 Auth method
        printf "\n"
        printf "  %sAuthentication method:%s\n" "$C_WHITE_BOLD" "$C_RESET"
        printf "    %s1.%s Password\n" "$C_DIM" "$C_RESET"
        printf "    %s2.%s SSH key only\n" "$C_DIM" "$C_RESET"
        printf "\n"
        local auth_choice
        auth_choice=$(prompt_input "Select (1-2)" "1")

        if [ "$auth_choice" = "2" ]; then
            # 3.3b SSH key
            AUTH_METHOD="sshkey"
            printf "\n"
            NEW_SSH_KEY=$(prompt_input "SSH public key (ssh-ed25519 ...)")
            if [ -z "$NEW_SSH_KEY" ]; then
                print_error "SSH key cannot be empty"
                print_footer false "Setup failed"
                exit 1
            fi
            print_success "SSH key configured"

            # Ask about disabling password auth
            printf "\n"
            if prompt_yes_no "Disable SSH password authentication?"; then
                DISABLE_PASSWORD_AUTH=true
                print_success "Password auth will be disabled"
            fi
        else
            # 3.3a Password
            AUTH_METHOD="password"
            printf "\n"
            printf "  %sEnter password for %s:%s\n" "$C_DIM" "$NEW_USERNAME" "$C_RESET"
            read -s -p "  Password: " user_password
            printf "\n"
            read -s -p "  Confirm:  " user_password_confirm
            printf "\n"

            if [ "$user_password" != "$user_password_confirm" ]; then
                print_error "Passwords do not match"
                print_footer false "Setup failed"
                exit 1
            fi

            if [ -z "$user_password" ]; then
                print_error "Password cannot be empty"
                print_footer false "Setup failed"
                exit 1
            fi

            # Hash password
            NEW_PASSWORD_HASH=$(echo "$user_password" | mkpasswd -m sha-512 --stdin)
            print_success "Password configured"
        fi
    else
        print_info "Keeping default user (default/pwd)"
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
