{
  pkgs,
  lib,
  ...
}:

{
  # ============================================================================
  # Nix Configuration
  # ============================================================================
  system.stateVersion = "25.11";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;
  services.tzupdate.enable = true;

  # ============================================================================
  # Packages
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # ---- Version control -----------------------------------------------------
    git

    # ---- Nix OS --------------------------------------------------------------
    nix-output-monitor
    nixfmt-rfc-style

    # ---- System utilities ----------------------------------------------------
    wget
    curl
    lsof
    ncdu
    tmux

    # ---- Quality of life -----------------------------------------------------
    unzip
    zip
    glances
  ];

  # ============================================================================
  # Shell
  # ============================================================================
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
      theme = "agnoster";
    };
  };

  users.users.root.shell = pkgs.zsh;

  # ============================================================================
  # Security
  # ============================================================================
  security.sudo.wheelNeedsPassword = lib.mkDefault false;
}
