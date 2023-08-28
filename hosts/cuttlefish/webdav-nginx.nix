{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; let
  webdav-david = pkgs.writeText "webdav-david" ''
    david
  '';
in {
  config = {
    security.pam.services.nginx-david = {
      #unixAuth = true;
      #setEnvironment = false;

      text = ''
        # Account management.
        account required pam_unix.so

        # Authentication management.
        auth sufficient pam_unix.so   likeauth try_first_pass
        auth required pam_listfile.so  item=user sense=allow onerr=fail file=${webdav-david}
        auth required pam_deny.so

        # Password management.
        password sufficient pam_unix.so nullok sha512

        # Session management.
        session required pam_unix.so
      '';

      # https://stackoverflow.com/a/47041843
      #text = lib.mkDefault (
      #  lib.mkBefore ''
      #    auth required pam_listfile.so \
      #      item=user sense=allow onerr=fail file=${webdav-david}
      #  ''
      #);
    };

    # PAM settings
    # https://nixos.wiki/wiki/Nginx#Authentication_via_PAM
    security.pam.services.nginx.setEnvironment = false;
    systemd.services.nginx.serviceConfig = {
      ReadWritePaths = ["/webdav"];
      #SupplementaryGroups = [ "shadow" "1000" ];
      #SupplementaryGroups = [ "shadow" "users" ];

      SupplementaryGroups = ["shadow"];
      NoNewPrivileges = lib.mkForce false;
      PrivateDevices = lib.mkForce false;
      ProtectHostname = lib.mkForce false;
      ProtectKernelTunables = lib.mkForce false;
      ProtectKernelModules = lib.mkForce false;
      RestrictAddressFamilies = lib.mkForce [];
      LockPersonality = lib.mkForce false;
      MemoryDenyWriteExecute = lib.mkForce false;
      RestrictRealtime = lib.mkForce false;
      RestrictSUIDSGID = lib.mkForce false;
      SystemCallArchitectures = lib.mkForce "";
      ProtectClock = lib.mkForce false;
      ProtectKernelLogs = lib.mkForce false;
      RestrictNamespaces = lib.mkForce false;
      SystemCallFilter = lib.mkForce "";
    };

    services.nginx = {
      enable = true;
      #user = "david";

      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      defaultHTTPListenPort = 12345;
      additionalModules = with pkgs.nginxModules; [
        pam
        dav
      ];

      virtualHosts = {
        "cuttlefish" = {
          default = true;

          locations."/" = {
            #root = "/slow/documents";
            root = "/webdav/files";
            #basicAuth = {
            #  david = "password";
            #};

            extraConfig = ''
              # dav
              create_full_put_path on;
              dav_methods PUT DELETE MKCOL COPY MOVE;
              dav_ext_methods PROPFIND OPTIONS;
              dav_access user:rw group:rw all:rw;

              autoindex on;
              #client_max_body_size 0;
              #client_body_temp_path /slow/documents/tmp;
              client_body_temp_path /webdav/tmp;

              # allow all;

              # PAM auth
              auth_pam  "Password Required";
              #auth_pam_service_name "nginx";
              auth_pam_service_name "nginx-david";

              #limit_except GET {
              #    allow 192.168.1.0/32;
              #    allow 100.64.0.0/10;
              #    deny  all;
              #}
            '';
          };
        };
      };
    };
    #security.pam.services.webdav = {
    #  unixAuth = true;
    #  setEnvironment = false;
    #};

    ## WebDAV
    #services.webdav-server-rs = {
    #  enable = true;
    #  settings = {
    #    server = {
    #      listen = [ "0.0.0.0:4918" "[::]:4918" ];
    #      uid = 1000;
    #      gid = 100;
    #    };

    #    accounts = {
    #      auth-type = "pam";
    #      acct-type = "unix";
    #      realm = "Webdav Server";
    #    };

    #    #htpasswd.default = {
    #    #  htpasswd = "/etc/htpasswd";
    #    #};

    #    unix = {
    #      cache-timeout = 120;
    #      min-uid = 1000;
    #    };

    #    pam = {
    #      service = "other";
    #      cache-timeout = 120;
    #      threads = 8;
    #    };

    #    location = [
    #      {
    #        route = [ "/documents/*path" ];
    #        directory = "/slow/documents";
    #        methods = [ "webdav-ro" ];

    #        # TODO: make defaults
    #        handler = "filesystem";
    #        on_notfound = "return";

    #        auth = "true";
    #        setuid = false;
    #        autoindex = true;
    #        hide-symlinks = true;
    #        case-insensitive = "false";
    #      }
    #    ];
    #  };
    #};

    networking.firewall.allowedTCPPorts = [
      #4918
      12345
    ];
  };
}
