{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    # ./nix.nix
    # inputs.home-manager.darwinModules.home-manager
  ];

  # Temporary workaround since sops-nix checks a systemd options,
  # which doesn't exist in nix-darwin
  # options.systemd = lib.mkOption {
  #   type = lib.types.attrs;
  #   default = {};
  #   readOnly = true;
  # };
}
