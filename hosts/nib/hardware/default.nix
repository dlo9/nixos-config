# Hardware: https://www.minix.us/z83-4-mx
{ config, inputs, lib, pkgs, modulesPath, ... }:


let
  # diskId = "mmc-BJTD4R_0xddfc5f3b";
  diskId = "ata-QEMU_DVD-ROM_QM00001";
  adminUser = "david";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.disko.nixosModules.disko
    # ./generated.nix
    (import ./disks.nix { inherit adminUser diskId; })
    # (import ./filesystems.nix { inherit diskId; })
    ./quirks.nix
  ];

  # boot.loader.grub.enable = lib.mkForce false;
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.timeout = lib.mkForce 10;
  # boot.loader.efi.canTouchEfiVariables = lib.mkForce false;


  # boot.loader.efi.efiSysMountPoint = "/boot";
  # boot.loader.grub = {
  #   devices = [ config.disko.devices.disk.fast.device ];
  #   efiSupport = true;
  #   efiInstallAsRemovable = false;
  # };

  boot = {
    zfs.requestEncryptionCredentials = [
      "fast"
    ];

    # Must load network module on boot for SSH access
    # lspci -v | grep -iA8 'network\|ethernet'
    # initrd.availableKernelModules = [ "r8169" ];
    loader.grub.mirroredBoots = [
      {
        devices = [ config.disko.devices.disk.fast.device ];
        path = "/boot";
        # path = "/boot/efi0/EFI";
      }
    ];
  };

  # Only true when installing?
  disko.enableConfig = true;

  nixpkgs.hostPlatform = "x86_64-linux";
}
