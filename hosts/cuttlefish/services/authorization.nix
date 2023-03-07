{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
  sysCfg = config.sys;
  container = "keycloak";
in
{
  config = {
    # Secret
    sops.secrets."services/keycloak/postgres-password" = {
      sopsFile = sysCfg.secrets.hostSecretsFile;
      owner = config.users.users.nix-container1.name;
      group = config.users.users.nix-container1.group;
    };

    # Networking
    networking.nat = {
      enable = true;
      internalInterfaces = [ "ve-${container}" ];
      externalInterface = "lan";
    };

    # Nginx
    services.nginx.virtualHosts = {
      "${container}.sigpanic.com" = {
        useACMEHost = "sigpanic.com";
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://${container}.containers";
          proxyWebsockets = true;
        };
      };
    };

    # Containers
    containers = {
      keycloak = {
        autoStart = true;
        privateNetwork = true;

        hostAddress = "10.2.0.1";
        localAddress = "10.2.0.2";

        bindMounts = {
          "/secrets/postgres-password" = {
            hostPath = config.sops.secrets."services/keycloak/postgres-password".path;
          };
        };

        extraFlags = [
          # Can't ID map on the ramfs secrets mount (unverified theory)
          #"-U"
          "--private-users=identity"
          "--private-users-ownership=auto"

          "--link-journal=host"
          "--property=CPUQuota=100%"
          "--property=MemoryHigh=1G"
        ];

        config = {
          system.stateVersion = "22.05";

          networking.firewall = {
            enable = true;
            allowedTCPPorts = [ 80 ];
          };

          users.users.postgres.uid = config.users.users.nix-container1.uid;
          users.groups.postgres.gid = config.users.groups.nix-container1.gid;

          services.keycloak = {
            enable = true;

            settings = {
              hostname = "${container}.sigpanic.com";
              proxy = "edge";
            };

            database = {
              createLocally = true;
              passwordFile = "/secrets/postgres-password";
            };
          };
        };
      };
    };
  };
}
