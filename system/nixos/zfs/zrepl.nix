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

      send = {
        encrypted = true;
        send_properties = true;
      };
    });

  enable = config.boot.zfs.enabled && cfg.filesystems != {} && policies != [];
in {
  # ZFS autosnapshot and replication
  config = mkIf enable {
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
              };
            }
          ]
          ++ (map (job "local") policies)
          ++ (map (job "remote") policies);
      };
    };
  };
}
