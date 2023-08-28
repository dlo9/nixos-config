{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
with types; let
  cfg = config.sys.secrets;
in {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  options.sys.secrets = {
    enable = mkEnableOption "secrets management" // {default = true;};

    hostSecretsFile = mkOption {
      type = path;
      default = inputs.hostFile config.networking.hostName "secrets.yaml";
      description = "Host-specific secrets file";
    };
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ./shared.yaml;
      gnupg.sshKeyPaths = []; # Disable GPG, otherwise it'll search for

      age = {
        # This file must be in the filesystems mounted within the initfs.
        # I put it in the root filesystem since that's mounted first.
        keyFile = "/var/sops-age-keys.txt";
        sshKeyPaths = [];
      };
    };
  };
}
