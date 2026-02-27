{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];
}
