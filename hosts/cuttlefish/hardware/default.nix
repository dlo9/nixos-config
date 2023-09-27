{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd-pstate
    common-cpu-amd
    common-gpu-intel
    common-gpu-nvidia-disable
    common-hidpi

    ./quirks.nix
    ./generated.nix
  ];
}
