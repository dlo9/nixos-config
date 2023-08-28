{
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.zfs.devNodes = lib.mkForce "/dev/disk/by-path";
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  boot.kernelParams = ["nomodeset"];
}
