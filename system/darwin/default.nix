{
  config,
  inputs,
  pkgs,
  lib,
  hostname,
  ...
}: {
  imports = [
    ./nix.nix
    ./skhd.nix
    ./status-bar.nix
    ./system-settings.nix
    ./window-manager.nix
    inputs.home-manager.darwinModules.home-manager
  ];

  # Temporary workaround since sops-nix checks a systemd options,
  # which doesn't exist in nix-darwin
  options.systemd = lib.mkOption {
    type = lib.types.attrs;
    default = {};
    readOnly = true;
  };

  config = {
    #networking.hostName = hostname;
    programs.fish.enable = true;
    environment.shells = [pkgs.fish];
  };
}
