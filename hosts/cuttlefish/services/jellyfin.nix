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
      externalInterface = "cuttlefish";
    };

    # Containers
    containers = {
      "${container}" = {
        autoStart = true;
        privateNetwork = true;

        #hostBridge = "containers";
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

          "/dev/dri/renderD128" = { };
        };

        allowedDevices = [
          (rwDevice "/dev/dri/renderD128")
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
          # environment.sessionVariables = {
          #   # To use intel GPU as vaapi
          #   LIBVA_DRIVER_NAME = "iHD";
          # };

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
