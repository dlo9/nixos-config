{
  config,
  pkgs,
  lib,
  inputs,
  hostname,
  ...
}:
with lib; {
  imports = [
    ./hardware
    ./services
  ];

  config = {
    # Change name of the default user
    users.users.david.name = "pi";
    home-manager.users.david = import ./home.nix;

    nix.distributedBuilds = true;
    services.davfs2.enable = false;
    services.fwupd.enable = false;
    fix-efi.enable = false;

    system.stateVersion = "24.11";
  };
}
