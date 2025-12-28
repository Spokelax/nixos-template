{
  lib,
  ...
}:

{
  # ============================================================================
  # Boot Loader
  #     ---
  # Default: GRUB with separate /boot (ext4) and /boot/efi (FAT32 ESP).
  # This avoids FAT32 permission warnings from systemd-boot.
  #     ---
  # ============================================================================
  boot.loader.grub.enable = lib.mkDefault true;
  boot.loader.grub.efiSupport = lib.mkDefault true;
  boot.loader.grub.efiInstallAsRemovable = lib.mkDefault true;
  boot.loader.grub.device = lib.mkDefault "nodev";
  boot.loader.efi.efiSysMountPoint = lib.mkDefault "/boot/efi";
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault false;
}
