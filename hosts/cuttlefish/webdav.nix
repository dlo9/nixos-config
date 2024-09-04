{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; {
  config = {
    # WebDAV
    services.webdav-server-rs = {
      enable = true;

      # https://github.com/miquels/webdav-server-rs/blob/master/webdav-server.toml
      settings = {
        server = {
          listen = ["0.0.0.0:12345" "[::]:12345"];
        };

        # htpasswd auth
        accounts = {
          acct-type = "unix";
          auth-type = "htpasswd.default";
          realm = "cuttlefish";
        };

        htpasswd.default = {
          # mkpasswd -m sha-512
          htpasswd = pkgs.writeText "htpasswd" ''
            david:$6$lfXZQaVisXg6Gjqz$1dTcCAbHKnMjk.PJs0EUpSsG773FXma54tqaLGdMbDBmb7v848m/tA.46oI0ProdPd6b7u49U0d6h8Jq7wQK4/
            chelsea:$6$xCwfzfv87NxMTzqM$ZttnXW7GtkV8aeoWMqsuOjhi7RLiIVQtGt13p.0IUXemdN7CpsFrQj3yBGDp9WXYu9u/OXcpVw/FSzbHYZvbE/
          '';
        };

        unix = {
          cache-timeout = 120;
          min-uid = 1000;
        };

        location = [
          {
            route = ["/(*path)"];
            methods = ["webdav-rw"];
            directory = pkgs.linkFarm "webdav-root" {
              "documents" = "/home/david/documents";
              "media" = "/slow/media";
              "games" = "/slow/games";

              "chelsea-cuttlefish" = "/home/chelsea/documents";
              "backup/chelsea" = "/slow/backup/chelsea";
            };

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
