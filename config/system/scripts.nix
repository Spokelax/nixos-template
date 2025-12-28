{
  pkgs,
  ...
}:

{
  # ============================================================================
  # System Scripts
  #     ---
  # rebuild: Runs nixos-rebuild switch with nom (nix-output-monitor).
  #               Uses flake auto-match by hostname.
  #     ---
  # ============================================================================
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "rebuild" ''
      cd /etc/nixos
      exec sudo nixos-rebuild switch --flake . "$@" |& nom
    '')
  ];
}
