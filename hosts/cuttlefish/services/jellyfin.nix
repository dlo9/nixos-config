{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; {
  config = {
    hardware.graphics = {
      enable = mkDefault true;
      enable32Bit = pkgs.stdenv.isx86_64;
    };

    # Containers
    containers.jellyfin = {
      autoStart = true;
      privateNetwork = true;

      hostAddress = "10.2.0.1";
      localAddress = "10.2.0.3";

      bindMounts = {
        "/media/video" = {
          hostPath = "/slow/media/video";
        };

        "/media/audio/music" = {
          hostPath = "/slow/media/audio/Music";
        };

        "/run/opengl-driver" = {};

        "/dev/dri/renderD128" = {};
      };

      allowedDevices = [
        {
          modifier = "rw";
          node = "/dev/dri/renderD128";
        }
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
        networking.firewall.allowedTCPPorts = [8096];

        services.jellyfin = {
          enable = true;
          package = pkgs.unstable.jellyfin;
        };

        environment.etc."resolv.conf".text = "nameserver 1.1.1.1";

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
}
