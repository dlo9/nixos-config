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
          realm = "drywell";
        };

        htpasswd.default = {
          htpasswd = pkgs.writeText "htpasswd" ''
            david:$6$lfXZQaVisXg6Gjqz$1dTcCAbHKnMjk.PJs0EUpSsG773FXma54tqaLGdMbDBmb7v848m/tA.46oI0ProdPd6b7u49U0d6h8Jq7wQK4/
            sue:$2y$05$XKP3L/DsHkLMszi0sWRHAO9Yz3xgaRfyiRqH8cqYcATyQDzWRKlBO
            michael:$2y$05$1zRGWNFtecV1mxcrO8lSz.5sOmUqZSXRtwBw8W.soEh83Ryl37iS2
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
              "michael" = "/slow/documents/michael";
              "sue" = "/slow/documents/sue";
              "sue-server" = "/slow/documents/sue";

              "backup/sue" = "/slow/backups/sue";
              "backup/michael" = "/slow/backups/michael";
            };

            # TODO: make defaults
            handler = "filesystem";
            on_notfound = "return";

            auth = "true";
            setuid = true;
            autoindex = false;
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
