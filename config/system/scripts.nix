{
  pkgs,
  ...
}:

{
  # ============================================================================
  # System Scripts
  #     ---
  # nixos-switch: Runs nixos-rebuild switch with nom (nix-output-monitor).
  #               Uses flake auto-match by hostname.
  #     ---
  # ============================================================================
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "nixos-switch" ''
      cd /etc/nixos
      exec sudo nixos-rebuild switch --flake . "$@" |& nom
    '')
  ];
}
