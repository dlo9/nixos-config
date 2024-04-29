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
    common-hidpi

    #./nvidia.nix
    ./quirks.nix
    ./generated.nix
  ];

  hardware.opengl.extraPackages = with pkgs; [
    intel-compute-runtime
  ];
}
