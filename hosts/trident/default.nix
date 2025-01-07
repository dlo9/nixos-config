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

    # Disable some thing that fwupd enables to save space
    services.fwupd.daemonSettings.DisabledPlugins = [
      # No UEFI, so disable it:
      # https://github.com/fwupd/fwupd/wiki/PluginFlag:capsules-unsupported
      "test"
      "test_ble"
      "invalid"
      "bios"
    ];

    fix-efi.enable = false;

    sdImage = {
      populateRootCommands = ''
        mkdir files/etc
        cp -r ${inputs.self} files/etc/nixos

        mkdir files/var
        chmod 755 files/var

        cp "/impure/sops-age-keys.txt" "files/var/sops-age-keys.txt"
        chmod 600 "files/var/sops-age-keys.txt"
      '';
    };

    system.stateVersion = "24.11";
  };
}
