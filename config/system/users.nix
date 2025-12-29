{
  lib,
  pkgs,
  ...
}:

{
  # ============================================================================
  # Default User (Setup)
  #     ---
  # Bootstrap user for initial setup. Override in host config.
  # Default password: "pwd" (change immediately after first login).
  #     ---
  # ============================================================================
  users.users.default = lib.mkDefault {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "pwd";
    shell = pkgs.zsh;
  };
}
