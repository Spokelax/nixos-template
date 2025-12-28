{
  lib,
  ...
}:

{
  # ============================================================================
  # Global Secrets
  #     ---
  # Provides config.my.secretsFile for use in any module.
  # Place your secrets at /etc/nixos/.env (gitignored).
  #     ---
  # ============================================================================
  options.my.secretsFile = lib.mkOption {
    type = lib.types.path;
    default = /etc/nixos/.env;
    description = "Path to global secrets env file";
  };
}
