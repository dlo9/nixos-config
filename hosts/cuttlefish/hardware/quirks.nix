{
  pkgs,
  lib,
  ...
}:
with lib; {
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.efi.canTouchEfiVariables = false;
}
