# ============================================================================
# Host Index
#     ---
# 1. Copy this file to default.nix
# 2. Run: nixos-generate-config --show-hardware-config > hardware.nix
# 3. Create config.nix (see example below)
# 4. Update hostname below
# 5. First rebuild:
#      sudo nixos-rebuild switch --flake . --experimental-features "nix-command flakes"
# 6. Future rebuilds:
#      rebuild
#     ---
# ============================================================================

{ mkHost }:

{
  "my-host" = mkHost {
    hostname = "my-host";
    system = "x86_64-linux";
    modules = [
      ./config.nix
      ./hardware.nix
    ];
  };
}

# ============================================================================
# config.nix example
# ============================================================================
#
#     { ... }:
#
#     {
#       # Bootstrap user: default / pwd
#
#       users.users.user = {
#         isNormalUser = true;
#         extraGroups = [ "wheel" ];
#         openssh.authorizedKeys.keys = [ "ssh-ed25519 ..." ];
#       };
#     }
#
# ============================================================================
