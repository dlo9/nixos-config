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
    common-pc-laptop-ssd
    common-cpu-amd
    common-cpu-amd-pstate
    common-gpu-amd

    # ./quirks.nix
    ./generated.nix
  ];

  services.tlp.enable = true;

  # Try out zen kernel
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
}
