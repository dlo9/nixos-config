{
  config,
  lib,
  pkgs,
  inputs,
  hostname,
  mylib,
  ...
}:
with lib; {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    defaultSopsFile = mkDefault mylib.secrets.hostSops hostname;
    gnupg.sshKeyPaths = mkDefault []; # Disable automatic SSH key import

    age = {
      # This file must be in the filesystems mounted within the initfs.
      # I put it in the root filesystem since that's mounted first.
      keyFile = mkDefault "${config.xdg.configHome}/sops-age-keys.txt";
      sshKeyPaths = mkDefault []; # Disable automatic SSH key import
    };

    # Set secrets for the current host
    secrets = mylib.secrets.hostSecrets hostname;
  };
}
