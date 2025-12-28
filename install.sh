#!/usr/bin/env bash

# NixOS Template Installer
# ==============================================================================
# Automated NixOS installation for VMs
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/Spokelax/nixos-template/master/install.sh | sudo bash
# ==============================================================================

set -e

# ==============================================================================
# Setup
# ==============================================================================

REPO_RAW="https://raw.githubusercontent.com/Spokelax/nixos-template/master"
REPO_GIT="https://github.com/Spokelax/nixos-template.git"
INSTALL_DIR=$(mktemp -d /tmp/nixos-install.XXXXXX)

cleanup() {
    # Safety: only delete if path is valid and matches expected pattern
    if [[ -n "$INSTALL_DIR" && "$INSTALL_DIR" == /tmp/nixos-install.* && -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
    fi
}
trap cleanup EXIT

# Fetch cli-utils
for f in colors.sh print.sh prompts.sh; do
    curl -sL "$REPO_RAW/.lib/cli-utils/$f" -o "$INSTALL_DIR/$f"
    source "$INSTALL_DIR/$f"
done

# ==============================================================================
# Variables
# ==============================================================================

TARGET_DISK=""
BOOT_PART=""
ROOT_PART=""
HOSTNAME=""

# ==============================================================================
# Functions
# ==============================================================================

print_warning_banner() {
    printf "\n"
    printf "%s════════════════════════════════════════════════════════════%s\n" "$C_RED_BOLD" "$C_RESET"
    printf "%s  WARNING - DESTRUCTIVE OPERATION%s\n" "$C_RED_BOLD" "$C_RESET"
    printf "%s════════════════════════════════════════════════════════════%s\n" "$C_RED_BOLD" "$C_RESET"
    printf "  This script will %sERASE%s the target disk and install NixOS.\n" "$C_RED_BOLD" "$C_RESET"
    printf "\n"
    printf "  %sIntended for fresh VMs only.%s\n" "$C_WHITE_BOLD" "$C_RESET"
    printf "  %sFor special setups, install manually:%s\n" "$C_DIM" "$C_RESET"
    printf "  %s  -> %s%s\n" "$C_DIM" "$REPO_GIT" "$C_RESET"
    printf "%s════════════════════════════════════════════════════════════%s\n" "$C_RED_BOLD" "$C_RESET"
}

print_steps_overview() {
    printf "\n"
    printf "  %sThis script will:%s\n" "$C_WHITE_BOLD" "$C_RESET"
    printf "    %s1.%s Partition disk (GPT, ESP + root)\n" "$C_DIM" "$C_RESET"
    printf "    %s2.%s Format (FAT32 boot, ext4 root)\n" "$C_DIM" "$C_RESET"
    printf "    %s3.%s Clone nixos-template from GitHub\n" "$C_DIM" "$C_RESET"
    printf "    %s4.%s Generate hardware config\n" "$C_DIM" "$C_RESET"
    printf "    %s5.%s Run nixos-install\n" "$C_DIM" "$C_RESET"
    printf "\n"
}

detect_disk() {
    local disks
    disks=$(lsblk -d -n -o NAME,TYPE | awk '$2=="disk" {print $1}' | grep -v -E '^loop|^sr' || true)
    local disk_count
    disk_count=$(echo "$disks" | grep -c . || echo 0)

    if [ "$disk_count" -eq 0 ]; then
        print_error "No disks found"
        exit 1
    elif [ "$disk_count" -eq 1 ]; then
        TARGET_DISK="/dev/$disks"
        set_partition_names
        print_success "Detected disk: $TARGET_DISK"
    else
        printf "\n"
        printf "  %sMultiple disks found:%s\n" "$C_WHITE_BOLD" "$C_RESET"
        local i=1
        for disk in $disks; do
            local size
            size=$(lsblk -d -n -o SIZE "/dev/$disk")
            printf "    %s%d.%s /dev/%s (%s)\n" "$C_DIM" "$i" "$C_RESET" "$disk" "$size"
            i=$((i + 1))
        done
        printf "\n"
        local selection
        selection=$(prompt_input "Select disk (1-$disk_count)")
        TARGET_DISK="/dev/$(echo "$disks" | sed -n "${selection}p")"
        set_partition_names
        print_success "Selected disk: $TARGET_DISK"
    fi
}

set_partition_names() {
    # NVMe uses 'p' prefix for partitions, SATA/SCSI doesn't
    if [[ "$TARGET_DISK" == /dev/nvme* ]]; then
        BOOT_PART="${TARGET_DISK}p1"
        ROOT_PART="${TARGET_DISK}p2"
    else
        BOOT_PART="${TARGET_DISK}1"
        ROOT_PART="${TARGET_DISK}2"
    fi
}

partition_disk() {
    print_info "Partitioning $TARGET_DISK..."
    parted -s "$TARGET_DISK" -- mklabel gpt
    parted -s "$TARGET_DISK" -- mkpart ESP fat32 1MB 512MB
    parted -s "$TARGET_DISK" -- set 1 esp on
    parted -s "$TARGET_DISK" -- mkpart primary 512MB 100%
    print_success "Partitioned disk"
}

format_disk() {
    print_info "Formatting partitions..."
    mkfs.fat -F 32 -n boot "$BOOT_PART"
    mkfs.ext4 -L nixos "$ROOT_PART"
    print_success "Formatted partitions"
}

mount_disk() {
    print_info "Mounting filesystems..."
    mount /dev/disk/by-label/nixos /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/boot /mnt/boot
    print_success "Mounted filesystems"
}

clone_template() {
    print_info "Cloning template..."
    git clone "$REPO_GIT" /mnt/etc/nixos
    print_success "Cloned to /mnt/etc/nixos"
}

generate_config() {
    print_info "Generating hardware config..."
    mkdir -p /mnt/etc/nixos/hosts
    nixos-generate-config --root /mnt --show-hardware-config > /mnt/etc/nixos/hosts/hardware.nix
    print_success "Generated hardware.nix"

    print_info "Creating host config..."
    cat > /mnt/etc/nixos/hosts/default.nix << EOF
# ============================================================================
# Host Index
# ============================================================================

{ mkHost }:

{
  "$HOSTNAME" = mkHost {
    hostname = "$HOSTNAME";
    system = "x86_64-linux";
    modules = [
      ./config.nix
      ./hardware.nix
    ];
  };
}
EOF

    cat > /mnt/etc/nixos/hosts/config.nix << EOF
# ============================================================================
# Host Configuration
# ============================================================================

{ ... }:

{
  # Add host-specific configuration here
}
EOF
    print_success "Created host config for: $HOSTNAME"
}

run_install() {
    print_info "Running nixos-install (this may take a while)..."
    nixos-install --no-root-passwd --flake "/mnt/etc/nixos#$HOSTNAME"
    print_success "Installation complete"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    print_warning_banner
    print_steps_overview

    # Detect/select disk
    detect_disk

    # Prompt hostname
    printf "\n"
    HOSTNAME=$(prompt_input "Hostname" "nixos-template")
    if [ -z "$HOSTNAME" ]; then
        print_error "Hostname cannot be empty"
        exit 1
    fi
    print_success "Hostname: $HOSTNAME"

    # Confirm #1
    printf "\n"
    printf "  %sTarget:%s %s\n" "$C_WHITE_BOLD" "$C_RESET" "$TARGET_DISK"
    printf "  %sHostname:%s %s\n" "$C_WHITE_BOLD" "$C_RESET" "$HOSTNAME"
    printf "\n"
    if ! prompt_yes_no "Proceed with setup?"; then
        print_info "Aborted"
        exit 0
    fi

    # Execute steps 1-4
    steps_init 5
    print_step "Partitioning"
    partition_disk

    print_step "Formatting"
    format_disk

    print_step "Mounting"
    mount_disk

    print_step "Cloning & Configuring"
    clone_template
    generate_config

    # Pause before install
    printf "\n"
    printf "  %sConfig ready at:%s /mnt/etc/nixos\n" "$C_WHITE_BOLD" "$C_RESET"
    printf "  %sYou can inspect or modify before continuing.%s\n" "$C_DIM" "$C_RESET"
    printf "\n"
    if ! prompt_yes_no "Run nixos-install?"; then
        print_info "Stopped before install. Mounts preserved."
        print_info "To continue manually: nixos-install --flake /mnt/etc/nixos#$HOSTNAME"
        exit 0
    fi

    # Execute step 5
    print_step "Installing"
    run_install

    # Done
    print_footer true "NixOS installed successfully"
    printf "  %sNext:%s Reboot and login as 'default' (password: 'pwd')\n" "$C_WHITE_BOLD" "$C_RESET"
    printf "\n"
    if prompt_yes_no "Reboot now?"; then
        reboot
    fi
}

main "$@"
