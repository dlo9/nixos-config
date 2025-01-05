{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = with inputs.nixos-hardware.nixosModules; [
    common-pc-ssd
    raspberry-pi-4 # TODO: Change to 4

    ./disks.nix
    # ./quirks.nix
    # ./generated.nix
  ];

  services.tlp.enable = true;

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];

  # Try out zen kernel
  # boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = false;
}
