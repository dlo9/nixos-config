{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.zrepl;

  prefix = "zrepl_";
  categoryPrefix = category: "${prefix + category}_";

  keeps = {
    unreplicated = {
      type = "not_replicated";
    };

    all = {
      type = "regex";
      regex = ".*";
    };

    manual = {
      type = "regex";
      regex = "^${prefix}.*";
      negate = true;
    };
  };

  filters = category: mapAttrs (filesystem: fsCategory: fsCategory == category.name) cfg.filesystems;

  keep = category: [
    {
      # Prune category-related snapshots as appropriate
      type = "grid";
      grid = category.prunePolicy;
      regex = "^${categoryPrefix category.name}.*";
    }
    {
      # Keep all others
      type = "regex";
      regex = "^${categoryPrefix category.name}.*";
      negate = true;
    }
  ];

  pruning = category:
    if category.replicate
    then {
      keep_sender = keep category;
      keep_receiver = keep category;
    }
    else {
      keep = keep category;
    };

  job = category: ({
      name = "snapshot for ${category.name}-retention";
      type = "snap";

      filesystems = filters category;
      pruning = pruning category;

      snapshotting = {
        type = "periodic";
        prefix = categoryPrefix category.name;
        interval = cfg.interval;
      };
    }
    // (optionalAttrs category.replicate {
      type = "push";

      connect = {
        type = "tcp";
        address = cfg.replicateTo;
      };

      send = {
        raw = true;
        send_properties = true;
      };
    }));

  hasFileSystems = job: any id (attrValues job.filesystems);

  enable = config.boot.zfs.enabled && cfg.filesystems != {} && cfg.categories != {};
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

        jobs = filter hasFileSystems (map job (attrValues cfg.categories));
      };
    };
  };
}
