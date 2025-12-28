{
  lib,
  ...
}:

{
  # ============================================================================
  # OpenSSH Server (SSH & SFTP)
  # ============================================================================
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkDefault "prohibit-password";
      PasswordAuthentication = lib.mkDefault false;
      KbdInteractiveAuthentication = false;
    };
    extraConfig = ''
      Subsystem sftp internal-sftp
    '';
  };

  # ============================================================================
  # Required Ports
  # ============================================================================
  networking.firewall.allowedTCPPorts = [ 22 ];
}
