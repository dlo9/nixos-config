{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  config = {
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [1111];

    # ZFS autosnapshot and replication
    services.zrepl.settings.jobs = [
      {
        name = "replication sink";
        type = "sink";
        root_fs = "slow/replication";

        recv = {
          # https://zrepl.github.io/configuration/sendrecvoptions.html#placeholders
          placeholder.encryption = "off";
          properties.override = {
            canmount = "off";
            mountpoint = "none";
            refreservation = "none";
            "org.openzfs.systemd:ignore" = "on";
            overlay = "off";
          };
        };

        serve = {
          type = "tcp";
          listen = "100.97.145.42:1111";
          listen_freebind = true;

          clients = {
            "100.111.108.84" = "pavil";
            "100.78.52.90" = "drywell";
          };
        };
      }
    ];

    zrepl = {
      remote = "drywell.fairy-koi.ts.net:1111";

      filesystems = {
        "<".local = "year";

        "fast/home<" = {
          local = "year";
          remote = "week";
        };

        "slow/media/photos/immich/library<" = {
          local = "year";
          remote = "week";
        };

        "fast/home/david/.cache<".local = "week";
        "fast/home/david/code<".local = "week";
        "fast/home/david/Downloads<".local = "week";
        "fast/nixos/nix<".local = "week";

        "slow/smb/chelsea-backup<".local = "week";

        # Small services
        "fast/services<" = {
          local = "year";
          remote = "week";
        };

        # Large services
        "fast/services/plex<".remote = "unmanaged";
        "fast/services/photoprism<".remote = "unmanaged";
        "slow/services/deluge/downloads<" = {};

        # Container cache
        "fast/docker<".local = "week";
        "fast/containerd<".local = "day";

        # Unmanaged
        "slow/trash<" = {};
        "slow/replication<" = {};
        "slow/backup/drywell<" = {};
        "fast/reserved<" = {};
      };
    };
  };
}
