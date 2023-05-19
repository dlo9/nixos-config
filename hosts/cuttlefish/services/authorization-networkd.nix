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
      externalInterface = "enp39s0";
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

    # environment.etc = {
    #   "systemd/network/80-container-ve.network" = {
    #     source = "${pkgs.systemd}/lib/systemd/network/80-container-ve.network";
    #   };
    # };

    # Containers
    containers = {
      keycloak = {
        autoStart = true;
        # privateNetwork = true;

        # hostAddress = "10.2.0.1";
        # localAddress = "10.2.0.2";

        bindMounts = {
          "/secrets/postgres-password" = {
            hostPath = config.sops.secrets."services/keycloak/postgres-password".path;
          };
        };

        extraFlags = [
          # Can't ID map on the ramfs secrets mount (unverified theory)
          #"-U"
          # "--private-users=identity"
          # "--private-users-ownership=auto"

          # Fix filesystem permissions with this
          # https://wiki.archlinux.org/title/Systemd-nspawn#Unprivileged_containers
          "--private-users=0"
          "--private-users-ownership=chown"

          # Add networking
          "--network-veth"
          # "--network-zone=keycloak"

          "--link-journal=host"
          "--property=CPUQuota=100%"
          "--property=MemoryHigh=1G"
        ];

        config = {
          system.stateVersion = "22.05";

          networking = {
            # https://github.com/NixOS/nixpkgs/issues/69414#issuecomment-770755154
            useHostResolvConf = false;
            useDHCP = false;
            useNetworkd = true;

            firewall = {
              enable = true;
              allowedTCPPorts = [ 80 ];
            };
          };

          systemd.network.enable = true;
          systemd.network.networks."20-host0" = {
            matchConfig = {
              Virtualization = "container";
              Name = "host0";
            };

            dhcpConfig.UseTimezone = "yes";
            networkConfig = {
              DHCP = "yes";
              LLDP = "yes";
              EmitLLDP = "customer-bridge";
              LinkLocalAddressing = mkDefault "ipv6";
            };
          };

          # Link virtual host link configuration unit
          # environment.etc = {
          #   "systemd/network/80-container-host0.network" = {
          #     source = "${pkgs.systemd}/lib/systemd/network/80-container-host0.network";
          #   };
          # };

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
