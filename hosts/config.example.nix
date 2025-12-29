# ============================================================================
# Host Configuration Example
#     ---
# 1. Copy this file to config.nix
# 2. Run: nixos-generate-config --show-hardware-config > hardware.nix
# 3. Update hostname and configuration below
# 4. Stage: git add -A
# 5. First rebuild:
#      sudo nixos-rebuild switch --flake . --option experimental-features 'nix-command flakes'
# 6. Future rebuilds: sudo nixos-switch
#     ---
# ============================================================================

{ mkHost }:

{
  "my-host" = mkHost {
    hostname = "my-host";
    system = "x86_64-linux";
    modules = [
      ./hardware.nix

      ({ pkgs, ... }: {
        # ----------------------------------------------------------------------
        # Users
        # ----------------------------------------------------------------------

        # Disable bootstrap user
        users.users.default = {
          isNormalUser = false;
          hashedPassword = "!";  # Locked
        };

        # Your user (choose ONE auth method)
        users.users.myuser = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];

          # Option 1: Password (generate with: mkpasswd -m sha-512)
          # hashedPassword = "$6$...";

          # Option 2: SSH key
          # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];

          # Optional: Use zsh (oh-my-zsh configured in base)
          # shell = pkgs.zsh;
        };

        # Optional: Disable SSH password auth (SSH key only)
        # services.openssh.settings.PasswordAuthentication = false;

        # ----------------------------------------------------------------------
        # Services
        # ----------------------------------------------------------------------

        # services.nginx.enable = true;
      })
    ];
  };
}
