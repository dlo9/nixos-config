{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel

    ./generated.nix
  ];

  powerManagement.cpuFreqGovernor = "powersave";
}
