{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
  sysCfg = config.sys;
  container = "jellyfin";

  rwDevice = (node: {
    inherit node;
    modifier = "rw";
  });
in
{
  config = {
    # Networking
    networking.nat = {
      enable = true;
      internalInterfaces = [ "ve-${container}" ];
      externalInterface = "lan";
    };

    # Caddy
    reverseProxies = { jellyfin = "http://jellyfin.containers:8096"; };

    # Nginx
    services.nginx.virtualHosts = {
      "${container}.sigpanic.com" = {
        useACMEHost = "sigpanic.com";
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://${container}.containers:8096";
          proxyWebsockets = true;
        };
      };
    };

    # Containers
    containers = {
      "${container}" = {
        autoStart = true;
        privateNetwork = true;

        hostAddress = "10.2.0.1";
        localAddress = "10.2.0.3";

        bindMounts = {
          "/media/video" = {
            hostPath = "/slow/media/video";
          };

          "/media/video-optimized" = {
            hostPath = "/slowcache/media/video";
          };

          "/media/audio/music" = {
            hostPath = "/slow/media/audio/Music";
          };

          "/run/opengl-driver" = { };

          # "/dev/dri:idmap" = {
          #   hostPath = "/dev/dri";
          #   isReadOnly = false;
          # };

          # "/dev/dri/card0:idmap" = {
          #   hostPath = "/dev/dri/card0";
          #   isReadOnly = false;
          # };

          # "/dev/dri/card1:idmap" = {
          #   hostPath = "/dev/dri/card1";
          #   isReadOnly = false;
          # };

          # "/dev/dri/renderD128:idmap" = {
          #   hostPath = "/dev/dri/renderD128";
          #   isReadOnly = false;
          # };

          "/dev/dri/card0" = { };
          "/dev/dri/card1" = { };
          "/dev/dri/renderD128" = { };
          "/dev/nvidia0" = { };
          "/dev/nvidiactl" = { };
          "/dev/nvidia-modeset" = { };
          "/dev/nvidia-uvm" = { };
          "/dev/nvidia-uvm-tools" = { };
        };

        allowedDevices = [
          (rwDevice "/dev/dri/card0")
          (rwDevice "/dev/dri/card1")
          (rwDevice "/dev/dri/renderD128")
          (rwDevice "/dev/nvidia0")
          (rwDevice "/dev/nvidiactl")
          (rwDevice "/dev/nvidia-modeset")
          (rwDevice "/dev/nvidia-uvm")
          (rwDevice "/dev/nvidia-uvm-tools")
        ];

        extraFlags = [
          # Can't ID map on the ramfs secrets mount (unverified theory)
          #"-U"
          # "--private-users=identity"
          # "--private-users-ownership=auto"

          # Fix filesystem permissions with this
          # https://wiki.archlinux.org/title/Systemd-nspawn#Unprivileged_containers
          "--private-users=0"
          "--private-users-ownership=chown"

          "--link-journal=host"
          "--property=CPUQuota=400%"
          "--property=MemoryHigh=2G"
        ];

        config = {
          system.stateVersion = "22.05";

          networking.firewall = {
            enable = true;
            allowedTCPPorts = [ 8096 ];
          };

          services.jellyfin = {
            enable = true;
          };

          users = {
            groups.jellyfin.gid = 568;
            users.jellyfin = {
              uid = 568;

              extraGroups = [
                "video"
                "render"
              ];
            };
          };

          system.activationScripts = {
            linkLegacyConfig = ''
              ln -sf /var/lib/jellyfin /config
            '';
          };
        };
      };
    };
  };
}
