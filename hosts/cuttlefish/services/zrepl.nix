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
      # replicateTo = "cuttlefish.dlo9.github.beta.tailscale.net:1111";

      filesystems = {
        "<" = "long";

        "fast/home/david/.cache<" = "local";
        "fast/home/david/code<" = "local";
        # "fast/home/david/Downloads<" = "short";
        "fast/nixos/nix<" = "local";

        "slow/smb/chelsea-backup<" = "short";

        # Container cache
        "fast/docker<" = "local";
        "fast/kubernetes/containerd<" = "local";

        # Unmanaged
        "slow/trash<" = "unmanaged";
        "slow/replication<" = "unmanaged";
        "slow/backup/drywell<" = "unmanaged";
        "fast/reserved<" = "unmanaged";
      };
    };
  };
}
