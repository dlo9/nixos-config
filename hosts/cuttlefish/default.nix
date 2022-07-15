{ config, pkgs, lib, ... }:

with lib;

let
  sysCfg = config.sys;
in
{
  config = {
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

        jobs = [
          {
            name = "pool snapshot";
            type = "snap";
            filesystems = {
              # Root enables
              "fast<" = true;
              "slow<" = true;

              # Disable replicated datasets, trash
              "slow/abyss<" = false;
              "slow/backup/drywell<" = false;
              "slow/trash<" = false;
            };

            snapshotting = {
              type = "periodic";
              interval = "15m";
              prefix = "zrepl_";
            };

            pruning = {
              keep = [
                {
                  type = "grid";
                  grid = "1x1h(keep=all) | 24x1h | 31x1d | 12x30d";
                  regex = "^zrepl_.*";
                }
                {
                  type = "regex";
                  regex = "^manual.*";
                }
              ];
            };
          }

          #{
          #  name = "drywell replication";
          #  type = "pull";
          #  root_fs = "slow/backup/drywell";
          #  interval = "24h";

          #  connect = {
          #    type = "ssh+stdinserver";
          #    host = "drywell.sigpanic.com";
          #    user = "root";
          #    port = 22;

          #    # TODO: use a real key
          #    identity_file: "/etc/zrepl/ssh/identity/id_rsa";
          #  };

          #  pruning = {
          #    keep_sender = [
          #      { type = "not_replicated"; }
          #      {
          #        type = "grid";
          #        grid = "1x1h(keep=all) | 24x1h | 31x1d | 12x30d";
          #        regex = "^auto-.*";
          #      }
          #      {
          #        type = "regex";
          #        regex = "^manual.*";
          #      }
          #      {
          #        type = "regex";
          #        regex = ".*";
          #      }
          #    ];

          #    keep_receiver = [
          #      {
          #        type = "grid";
          #        grid = "1x1h(keep=all) | 24x1h | 31x1d | 12x30d";
          #        regex = "^auto-.*";
          #      }
          #      {
          #        type = "regex";
          #        regex = "^manual.*";
          #      }
          #      {
          #        type = "regex";
          #        regex = ".*";
          #      }
          #    ];
          #  };
          #}
        ];
      };
    };
  };
}
