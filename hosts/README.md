# Hosts

VM-specific configuration.

## After Cloning a Template VM

Run onboarding to set hostname and regenerate hardware config:

```bash
cd /etc/nixos
sudo ./onboarding.sh
```

## Manual Setup

See `host.example.nix` for step-by-step instructions.

## Tracking Changes

Nix flakes only see git-tracked files. After modifying your config:

```bash
git add -A && git commit -m "message"
```

Or stage without committing (flake will warn about dirty tree):

```bash
git add -A
```

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

## Updating

Pull template updates:

```bash
git pull
```
