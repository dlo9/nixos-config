{ config, pkgs, lib, ... }:

with lib;
with types;

let
  sysCfg = config.sys;
  cfg = sysCfg.secrets;
in
{
  options.sys.secrets = {
    enable = mkEnableOption "secrets management" // { default = true; };

    hostname = mkOption {
      type = str;
      default = config.networking.hostName;
      description = "Hostname for host-specific secrets";
    };

    hostSecretsFile = mkOption {
      type = path;
      # TODO: make this path <secrets>, or a cfg option
      default = ../secrets/hosts/${cfg.hostname}.yaml;
      description = "Host-specific secrets file";
    };
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../secrets/shared.yaml;
      gnupg.sshKeyPaths = [ ];

      age = {
        # This file must be in the filesystems mounted within the initfs.
        # I put it in the root filesystem since that's mounted first.
        keyFile = "/var/sops-age-keys.txt";
        sshKeyPaths = [ ];
      };
    } // optionalAttrs (pathExists cfg.hostSecretsFile) {
      # Install keys specific to every host. If the host-secific key file exists,
      # then these keys should exist.

      # TODO: don't autogenerate host keys if they don't exist:
      # services.openssh.hostKeys = [];
      secrets = {
        "ssh_keys/ssh_host_ed25519_key" = {
          path = "/etc/ssh/ssh_host_ed25519_key";
          sopsFile = sysCfg.secrets.hostSecretsFile;
        };

        "ssh_keys/ssh_host_ed25519_key.pub" = {
          path = "/etc/ssh/ssh_host_ed25519_key.pub";
          mode = "0644";
          sopsFile = sysCfg.secrets.hostSecretsFile;
        };

        "ssh_keys/ssh_host_rsa_key" = {
          path = "/etc/ssh/ssh_host_rsa_key";
          sopsFile = sysCfg.secrets.hostSecretsFile;
        };

        "ssh_keys/ssh_host_rsa_key.pub" = {
          path = "/etc/ssh/ssh_host_rsa_key.pub";
          mode = "0644";
          sopsFile = sysCfg.secrets.hostSecretsFile;
        };
      };
    };
  };
}
