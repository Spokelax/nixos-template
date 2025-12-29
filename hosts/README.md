# Hosts

VM-specific configuration.

&nbsp;

## After Cloning a Template VM

1. Login with `default` / `pwd` (console or SSH)
2. Run onboarding:

```bash
cd /etc/nixos && sudo ./onboarding.sh
```

Onboarding will:

- Set hostname
- Create your user (password or SSH key)
- Disable the default bootstrap user
- Optionally disable password authentication

&nbsp;

## Manual Setup

See `host.example.nix` for step-by-step instructions.

&nbsp;

## Tracking Changes

Nix flakes only see git-tracked files. After modifying your config:

```bash
git add -A && git commit -m "message"
```

Or stage without committing (flake will warn about dirty tree):

```bash
git add -A
```

&nbsp;

## Structure

```text
hosts/
├── default.nix   # Host index (hostname → config)
├── config.nix    # Host-specific settings
└── hardware.nix  # Generated hardware config
```

&nbsp;

## Adding Services

Edit `config.nix` to add host-specific configuration, then rebuild:

```bash
rebuild
```

&nbsp;

## Updating

Pull template updates:

```bash
git pull
```
