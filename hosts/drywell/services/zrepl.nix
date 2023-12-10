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
          listen = "100.78.52.90:1111";
          listen_freebind = true;

          clients = {
            "100.97.145.42" = "cuttlefish";
          };
        };
      }
    ];

    zrepl = {
      replicateTo = "cuttlefish.dlo9.github.beta.tailscale.net:1111";

      filesystems = {
        "<" = "long";
        "fast/nixos/nix<" = "local";
        "slow/backups" = "local";

        # Unmanaged
        "fast/reserved<" = "unmanaged";
        "slow/replication<" = "unmanaged";
        "slow/reserved<" = "unmanaged";
      };
    };
  };
}
