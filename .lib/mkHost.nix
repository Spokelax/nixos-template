# ============================================================================
# mkHost - Host Configuration Builder
# ============================================================================

{ inputs, nixpkgs }:

{
  hostname,
  system,
  modules ? [],
}:

nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [
    ../config/system/basic.nix
    ../config/system/boot.nix
    ../config/system/secrets.nix
    ../config/system/scripts.nix
    ../config/system/users.nix
    ../config/system/cachix.nix
    ../config/networking/basic.nix
    ../config/networking/openssh.nix
    { networking.hostName = hostname; }
  ] ++ modules;
}
