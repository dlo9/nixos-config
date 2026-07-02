{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = with inputs.nixos-hardware.nixosModules; [
    common-pc-laptop
    common-pc-ssd
    common-cpu-amd
    common-cpu-amd-pstate
    common-gpu-amd

    # ./quirks.nix
    ./generated.nix
    ./datasets.nix
  ];

  services.tlp.enable = true;

  # Zen kernel, frequently breaks zfs module
  #boot.kernelPackages = pkgs.unstable.linuxKernel.packages.linux_zen;
  #boot.zfs.package = pkgs.unstable.zfs;
}
