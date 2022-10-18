{ config, pkgs, lib, ... }:

with lib;

let
  zreplDefaults = {
    pruning = {
      keep_sender = [
        { type = "not_replicated"; }

        # Keep up to a week
        {
          type = "grid";
          grid = "1x1h(keep=all) | 23x1h | 6x1d";
          regex = "^zrepl_short_.*";
        }

        # Keep up to a month
        {
          type = "grid";
          grid = "1x1h(keep=all) | 23x1h | 30x1d";
          regex = "^zrepl_medium_.*";
        }

        # Keep up to a year
        {
          type = "grid";
          grid = "1x1h(keep=all) | 23x1h | 30x1d | 11x30d";
          regex = "^zrepl_long_.*";
        }

        # Keep non-zrepl snapshots
        {
          type = "regex";
          regex = "^zrepl_.*";
          negate = true;
        }
      ];

      keep_receiver = [
        # Keep up to a week
        {
          type = "grid";
          grid = "1x1h(keep=all) | 23x1h | 6x1d";
          regex = "^zrepl_short_.*";
        }

        # Keep up to a month
        {
          type = "grid";
          grid = "1x1h(keep=all) | 23x1h | 30x1d";
          regex = "^zrepl_medium_.*";
        }

        # Keep up to a year
        {
          type = "grid";
          grid = "1x1h(keep=all) | 23x1h | 30x1d | 11x30d";
          regex = "^zrepl_long_.*";
        }

        # Keep non-zrepl snapshots
        {
          type = "regex";
          regex = "^zrepl_.*";
          negate = true;
        }
      ];
    };
  };
in
{
  config = {
    # ZFS autosnapshot and replication
    services.zrepl = {
      enable = true;
      settings = {
        global = {
          logging = [
            {
              type = "stdout";
              level = "warn";
              format = "human";
              time = true;
              color = true;
            }
          ];

          monitoring = [
            {
              type = "prometheus";
              listen = ":9091";
              listen_freebind = true;
            }
          ];
        };

        jobs =
          let
            # listToAttrs where the value is the same for all keys
            listToUnityAttrs = list: value: listToAttrs (forEach list (key: nameValuePair key value));

            # Order filesystems by retension time. If a filesystem is in two lists,
            # the shorter lifetime takes presidence:
            #   - no-repl: up to 1 day locally
            #   - short: up to 1 week remotely
            #   - medium: up to 1 month remotely
            #   - long: up to 1 year remotely

            retentionPolicies = {
              never = [
                # Trash
                "slow/trash<"

                # TODO: should disable snapshotting completely, or might break zrepl push/pull
                # Replicated datasets
                "slow/replication<"
                "slow/backup/drywell<"
              ];

              local = [
                # Caches
                "fast/home/david/.cache<"
                "fast/home/david/code<"
                "fast/home/david/Downloads<"
                "fast/nixos/nix<"
              ];

              short = [
                # Computer backups
                # TODO: move these
                # TODO: make local only, but up to a week?
                "slow/smb/chelsea-backup<"
              ];

              medium = [ ];

              long = [ "<" ];

            };

            # Turns an attrSet of { filesystem -> bool } where each filesystem in the given
            # policy is set to `true`, and each filesystem in other policies is set to `false`
            getReplicationPolicy = policy:
              let
                myFs = retentionPolicies."${policy}";
                otherFs = (flatten (mapAttrsToList (n: v: optionals (n != policy) v) retentionPolicies));
              in
              (listToUnityAttrs myFs true) // (listToUnityAttrs otherFs false);


            snapshotJob = retentionPolicy: rec {
              name = "snapshot ${retentionPolicy}-retention datasets";
              type = "snap";

              filesystems = getReplicationPolicy retentionPolicy;

              snapshotting = {
                type = "periodic";
                prefix = "zrepl_${retentionPolicy}_";
                interval = "15m";
              };

              # Keep everything, pruning will be done during replication
              pruning.keep = [
                {
                  type = "regex";
                  regex = ".*";
                }
              ];
            };
          in
          [
            #{
            #  name = "cuttlefish replication";
            #  type = "source";

            #  serve = {
            #    type = "tcp";
            #    listen = "100.111.108.84:8888";
            #    listen_freebind = true;
            #    clients = {
            #      "100.97.145.42" = "cuttlefish";
            #    };
            #  };

            #  # Only exclude filesystems which shouldn't replicate at all.
            #  # Otherwise, zrepl unnecessarily syncs the snapshots and then fails when deleting them
            #  filesystems = { "<" = true; } // listToUnityAttrs retentionPolicies.local false;

            #  send = {
            #    encrypted = true;
            #    large_blocks = true;
            #    compressed = true;
            #    embedded_data = true;
            #    raw = true;
            #  };

            #  snapshotting = {
            #    # Snapshots are done in separate jobs so that only one port is needed
            #    type = "manual";
            #  };
            #}

            # Snapshot jobs
            (snapshotJob "long")
            (snapshotJob "medium")
            (snapshotJob "short")
            (snapshotJob "local")

            # Pull job for pavil
            (recursiveUpdate zreplDefaults {
              name = "pavil replication";
              type = "pull";
              root_fs = "slow/replication/pavil"; # This must exist
              interval = "1h";

              connect = {
                type = "tcp";
                address = "pavil:8888";
              };

              recv = {
                # https://zrepl.github.io/configuration/sendrecvoptions.html#placeholders
                placeholder.encryption = "off";
                properties.override = {
                  canmount = "off";
                  refreservation = "none";
                };
              };
            })
          ];
      };
    };
  };
}
