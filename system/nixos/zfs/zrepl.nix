{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.zrepl;

  prefix = "zrepl_";
  regex = "^${prefix}.*";

  keep = policy: [
    {
      # Prune category-related snapshots as appropriate
      inherit regex;
      type = "grid";
      grid = cfg.retentionPolicies.${policy};
    }
    {
      # Keep all others
      inherit regex;
      type = "regex";
      negate = true;
    }
  ];

  keepAll = [
    {
      type = "regex";
      regex = ".*";
    }
  ];

  policies = attrNames cfg.retentionPolicies;

  # Type is local or remote
  job = type: policy:
    {
      name = "${type}-${policy}";
      type = "snap";
      snapshotting.type = "manual";
      pruning.keep = keep policy;

      filesystems = mapAttrs (name: fs: fs.${type} == policy) cfg.filesystems;
    }
    // (optionalAttrs (type == "remote") {
      type = "push";

      pruning = {
        keep_sender = keepAll;
        keep_receiver = keep policy;
      };

      connect = {
        type = "tcp";
        address = cfg.remote;
      };

      replication.concurrency.steps = mkDefault 8;

      send = {
        encrypted = true;
        send_properties = true;
      };
    });

  enable = config.boot.zfs.enabled && cfg.filesystems != {} && policies != [];

  jobs = listToAttrs (map (type: {
    name = type;
    value = map (policy: "${type}-${policy}") policies;
  }) ["local" "remote"]);

  wakeupJobCommands = mapAttrs (type: jobs: map (job: "zrepl signal wakeup ${job}") jobs) jobs;

  zreplHook = "${pkgs.writeShellApplication {
    name = "wakeup-local-jobs";

    runtimeInputs = [config.services.zrepl.package];

    text = ''
      set +o errexit
      set +o nounset
      set +o pipefail

      if [[ "$ZREPL_FS" == *"/"* ]] || [[ "$ZREPL_HOOKTYPE" == "pre_snapshot" ]] || [[ "$ZREPL_DRYRUN" == "true" ]]; then
        exit 0
      fi

      # Wakes up local jobs only
      ${concatStringsSep "\n      " wakeupJobCommands.local}

      true
    '';
  }}/bin/wakeup-local-jobs";
in {
  # ZFS autosnapshot and replication
  config = mkIf enable {
    systemd.services = {
      zrepl-replication-trigger = {
        path = [config.services.zrepl.package];

        script = concatStringsSep "\n" wakeupJobCommands.remote;

        startAt = "daily";
      };
    };

    services.zrepl = {
      enable = mkDefault enable;

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
        };

        jobs =
          [
            {
              name = "snapshots";
              type = "snap";

              # Only snapshot filesystems which have a retention policy
              # (so that "unmanaged" children can be ignored)
              filesystems = mapAttrs (name: fs: any (policy: elem policy policies) [fs.local fs.remote]) cfg.filesystems;

              # Keep everything
              pruning.keep = keepAll;

              snapshotting = {
                type = "periodic";
                prefix = prefix;
                interval = cfg.snapInterval;

                hooks = [
                  {
                    type = "command";
                    path = zreplHook;
                  }
                ];
              };
            }
          ]
          ++ (map (job "local") policies)
          ++ (map (job "remote") policies);
      };
    };
  };
}
