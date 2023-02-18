{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
  # nix-shell -p terraform-providers.htpasswd --run "htpasswd -nB david"
  htpasswd = pkgs.writeText "htpasswd" ''
    david:$2y$05$pe8DCM.Q8ojQZtYUnM.HP..Lw3IOfpywuVD6QLD5yZ3QNVm0ZyOPi
  '';

  webdav-root = pkgs.linkFarm "webdav-root" {
    "sue" = "/slow/smb/sue";
    "sue-backup" = "/slow/backup/sue";

    "michael" = "/slow/smb/michael";
    "michael-backup" = "/slow/backup/michael";
  };
in
{
  config = {
    services.webdav-server-rs = {
      enable = true;

      # https://github.com/miquels/webdav-server-rs/blob/master/webdav-server.toml
      settings = {
        server = {
          listen = [ "0.0.0.0:12345" "[::]:12345" ];
        };

        # htpasswd auth
        accounts = {
          acct-type = "unix";
          auth-type = "htpasswd.default";
          realm = "drywell";
        };

        htpasswd.default = {
          inherit htpasswd;
        };

        unix = {
          cache-timeout = 120;
          min-uid = 1000;
        };

        location = [
          {
            route = [ "/(*path)" ];
            directory = webdav-root;
            methods = [ "webdav-rw" ];

            # TODO: make defaults
            handler = "filesystem";
            on_notfound = "return";

            auth = "true";
            setuid = true;
            autoindex = true;
            hide-symlinks = false;
            case-insensitive = "false";
          }
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [
      12345
    ];
  };
}
