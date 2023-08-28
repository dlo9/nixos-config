{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  keepNotReplicated = {
    type = "not_replicated";
  };

  keepAll = {
    type = "regex";
    regex = ".*";
  };

  keepNonZrepl = {
    type = "regex";
    regex = "^zrepl_.*";
    negate = true;
  };
in {
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

        jobs = let
          # listToAttrs where the value is the same for all keys
          listToUnityAttrs = list: value: listToAttrs (forEach list (key: nameValuePair key value));

          # Order filesystems by retension time. If a filesystem is in two lists,
          # the shorter lifetime takes presidence:
          #   - no-repl: up to 1 day locally
          #   - short: up to 1 week remotely
          #   - medium: up to 1 month remotely
          #   - long: up to 1 year remotely

          retentionPolicies = {
            never = {
              filesystems = [
                # Trash
                "slow/trash<"

                # TODO: should disable snapshotting completely, or might break zrepl push/pull
                # Replicated datasets
                "slow/replication<"
                "slow/slow/replication<"

                "fast/nixos/nix<"
              ];
            };

            local = {
              filesystems = [
                # Caches
                "fast/home/david/.cache<"
                "fast/home/david/code<"
                "fast/home/david/Downloads<"

                "slow/backup<"
                "slowcache<"

                # Container cache
                "fast/kubernetes/docker<"
                "fast/kubernetes/containerd<"
              ];

              # Keep up to a week
              keepPolicy = {
                type = "grid";
                grid = "1x1h(keep=all) | 23x1h | 6x1d";
                regex = "^zrepl_local_.*";
              };
            };

            short = {
              filesystems = [
                # Computer backups
                # TODO: move these
                # TODO: make local only, but up to a week?
                "slow/backup<"
              ];

              # Keep up to a week
              keepPolicy = {
                type = "grid";
                grid = "1x1h(keep=all) | 23x1h | 6x1d";
                regex = "^zrepl_short_.*";
              };
            };

            medium = {
              filesystems = [];

              # Keep up to a month
              keepPolicy = {
                type = "grid";
                grid = "1x1h(keep=all) | 23x1h | 30x1d";
                regex = "^zrepl_medium_.*";
              };
            };

            long = {
              filesystems = ["<"];

              # Keep up to a year
              keepPolicy = {
                type = "grid";
                grid = "1x1h(keep=all) | 23x1h | 30x1d | 11x30d";
                regex = "^zrepl_long_.*";
              };
            };
          };

          # Turns an attrSet of { filesystem -> bool } where each filesystem in the given
          # policy is set to `true`, and each filesystem in other policies is set to `false`
          getReplicationPolicy = policy: let
            myFs = retentionPolicies."${policy}".filesystems;
            otherFs = flatten (mapAttrsToList (n: v: optionals (n != policy) v.filesystems) retentionPolicies);
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
            # TODO: change back to `keepAll` once we're replicating
            pruning.keep = [
              retentionPolicies."${retentionPolicy}".keepPolicy
              keepNonZrepl
            ];
          };
        in [
          # Snapshot jobs
          (snapshotJob "long")
          (snapshotJob "medium")
          (snapshotJob "short")
          (snapshotJob "local")

          # Pull job for pavil
          #{
          #  name = "pavil replication";
          #  type = "pull";
          #  root_fs = "slow/replication/pavil"; # This must exist
          #  interval = "1h";

          #  connect = {
          #    type = "tcp";
          #    address = "pavil:8888";
          #  };

          #  recv = {
          #    # https://zrepl.github.io/configuration/sendrecvoptions.html#placeholders
          #    placeholder.encryption = "off";
          #    properties.override = {
          #      canmount = "off";
          #      refreservation = "none";
          #    };
          #  };

          #  pruning = {
          #    keep_sender = [
          #      keepNotReplicated
          #      retentionPolicies.local.keepPolicy
          #      retentionPolicies.short.keepPolicy
          #      retentionPolicies.medium.keepPolicy
          #      retentionPolicies.long.keepPolicy
          #    ];

          #    keep_receiver = [
          #      retentionPolicies.short.keepPolicy
          #      retentionPolicies.medium.keepPolicy
          #      retentionPolicies.long.keepPolicy
          #    ];
          #  };
          #}
        ];
      };
    };
  };
}
