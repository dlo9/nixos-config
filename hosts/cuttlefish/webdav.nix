{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
  # nix-shell -p terraform-providers.htpasswd --run "htpasswd -nB david"
  # nix-shell -p apacheHttpd --run "htpasswd -nB david"
  htpasswd = pkgs.writeText "htpasswd" ''
    david:$2y$05$pe8DCM.Q8ojQZtYUnM.HP..Lw3IOfpywuVD6QLD5yZ3QNVm0ZyOPi
    chelsea:$2y$05$XngjpZNS3WVzR.1i.F695.Qh9NdJCbRPz9lpRBcESMi5kQFF5zvxi
  '';

  webdav-root = pkgs.linkFarm "webdav-root" {
    "documents" = "/slow/documents";
    "media" = "/slow/media";

    "chelsea-cuttlefish" = "/slow/smb/chelsea";
    "backup/chelsea" = "/slow/backup/chelsea";
  };
in
{
  config = {
    # PAM auth
    #security.pam.services.webdav = {
    #  unixAuth = true;
    #  setEnvironment = false;
    #};

    # WebDAV
    services.webdav-server-rs = {
      enable = true;

      # https://github.com/miquels/webdav-server-rs/blob/master/webdav-server.toml
      settings = {
        server = {
          listen = [ "0.0.0.0:12345" "[::]:12345" ];
        };

        # PAM auth (doesn't seem to work)
        #accounts = {
        #  auth-type = "pam";
        #  acct-type = "unix";
        #};

        #pam = {
        #  service = "webdav";
        #  cache-timeout = 120;
        #  threads = 8;
        #};

        # htpasswd auth
        accounts = {
          acct-type = "unix";
          auth-type = "htpasswd.default";
          realm = "cuttlefish";
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
