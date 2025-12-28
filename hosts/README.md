# Hosts

VM-specific configuration. This folder is gitignored (except examples).

## After Cloning a Template VM

Run onboarding to set hostname and regenerate hardware config:

```bash
cd /etc/nixos
sudo ./onboarding.sh
```

## Manual Setup

See `host.example.nix` for step-by-step instructions.

## Structure

```
hosts/
├── default.nix   # Host index (hostname → config)
├── config.nix    # Host-specific settings
└── hardware.nix  # Generated hardware config
```

## Adding Services

Edit `config.nix` to add host-specific configuration, then rebuild:

```bash
rebuild
```
