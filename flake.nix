{
  # ============================================================================
  # Inputs
  # ============================================================================
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  # ============================================================================
  # Outputs
  # ============================================================================
  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      mkHost = import ./.lib/mkHost.nix { inherit inputs nixpkgs; };
    in
    {
      nixosConfigurations = import ./hosts/config.nix { inherit mkHost; };
    };
}
