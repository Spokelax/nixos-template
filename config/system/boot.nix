{
  lib,
  ...
}:

{
  # ============================================================================
  # Boot Loader
  #     ---
  # Default: systemd-boot (UEFI). Override in host config if needed.
  #     ---
  # ============================================================================
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
}
