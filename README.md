# NixOS Template

Flake-based NixOS template for VMs.

&nbsp;

## Quick Start (Automated)

Boot the NixOS installer and run:

```bash
curl -sL https://raw.githubusercontent.com/Spokelax/nixos-template/main/install.sh | sudo bash
```

Default hostname is `nixos-template` (for Proxmox template creation). Override if installing directly.

&nbsp;

## Manual Install

For custom setups:

1. **Partition** - GPT with 512MB ESP + root
2. **Format** - FAT32 boot, ext4 root
3. **Mount** - `/mnt` and `/mnt/boot`
4. **Clone** - `git clone https://github.com/Spokelax/nixos-template.git /mnt/etc/nixos`
5. **Hardware config** - `nixos-generate-config --show-hardware-config > /mnt/etc/nixos/hosts/hardware.nix`
6. **Host config** - Create `hosts/default.nix` (see `hosts/host.example.nix`)

> [!TIP]
> Default channel is `nixos-unstable`. To use stable, edit `flake.nix` before install:
> `nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";`

7. **Install** - `nixos-install --flake /mnt/etc/nixos#hostname`

&nbsp;

## After Install

See [hosts/README.md](hosts/README.md) for:

- Cloned VM setup (onboarding.sh)
- Host configuration
- Adding services
