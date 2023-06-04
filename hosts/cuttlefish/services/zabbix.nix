{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

# let
#   stateDir = "/var/lib/zabbix";
#   cfg =
# in
{
  imports = [
    ./zabbixWeb.nix
  ];

  config = {
    sops.secrets."services/zabbix/postgres-password" = {
      sopsFile = config.sys.secrets.hostSecretsFile;
      # Possibly also zabbix-agent?
      owner = config.users.users.zabbix.name;
      group = config.users.users.zabbix.group;
    };

    services.zabbixServer = {
      enable = true;

      # listen.port = "10051";
      # openFirewall = false;
      # settings = {};

      database = {
        type = "pgsql";
        createLocally = false;

        # Re-add and disable `createLocally`
        # passwordFile = config.sops.secrets."services/zabbix/postgres-password".path;
      };
    };

    services.zabbixAgent = {
      enable = true;

      server = "localhost";

    };

    services.zabbixWebCaddy = {
      enable = true;

      database = {
        type = "pgsql";
        host = "localhost";

        # inherit passwordFile;
        # passwordFile = config.sops.secrets."services/zabbix/postgres-password".path;
      };
    };

    services.caddy.virtualHosts.zabbix = {
      useACMEHost = "sigpanic.com";
      serverAliases = [ "zabbix.sigpanic.com" ];
      extraConfig = ''
        # reverse_proxy http://${config.services.zabbixServer.listen.ip}:${toString config.services.zabbixServer.listen.port}

        php_fastcgi unix//${config.services.phpfpm.pools.zabbix.socket}
        root * ${config.services.zabbixWebCaddy.package}/share/zabbix
        file_server

        # php_fastcgi unix//run/php/php7.4-fpm.sock
      '';
    };

    # Enables "ident" authentication in postgres
    services.oidentd.enable = true;

    services.postgresql = {

      enable = true;
      # enableTCPIP = true;
      ensureDatabases = [ config.services.zabbixServer.database.name ];

      ensureUsers = [
        {
          name = config.services.zabbixServer.database.user;
          ensurePermissions = { "DATABASE ${config.services.zabbixServer.database.name}" = "ALL PRIVILEGES"; };
        }
      ];

      authentication = ''
        host ${config.services.zabbixServer.database.name} ${config.services.zabbixServer.database.user} samehost ident
      '';
    };

    # services.httpd.enable = mkForce false;

    # services.zabbixWeb assumes Apache HTTPD, which I don't want
    # services.phpfpm.pools.zabbix = {
    #   user = config.services.caddy.user;
    #   group = config.services.caddy.group;

    #   # Stolen from services.zabbixWeb
    #   phpOptions = ''
    #     # https://www.zabbix.com/documentation/current/manual/installation/install
    #     memory_limit = 128M
    #     post_max_size = 16M
    #     upload_max_filesize = 2M
    #     max_execution_time = 300
    #     max_input_time = 300
    #     session.auto_start = 0
    #     mbstring.func_overload = 0
    #     always_populate_raw_post_data = -1
    #     # https://bbs.archlinux.org/viewtopic.php?pid=1745214#p1745214
    #     session.save_path = ${stateDir}/session
    #   '';

    #   phpEnv.ZABBIX_CONFIG = pkgs.writeText "zabbix.conf.php" ''
    #     <?php
    #     // Zabbix GUI configuration file.
    #     global $DB;
    #     $DB['TYPE'] = '${ { mysql = "MYSQL"; pgsql = "POSTGRESQL"; oracle = "ORACLE"; }.${cfg.database.type} }';
    #     $DB['SERVER'] = '${cfg.database.host}';
    #     $DB['PORT'] = '${toString cfg.database.port}';
    #     $DB['DATABASE'] = '${cfg.database.name}';
    #     $DB['USER'] = '${cfg.database.user}';
    #     # NOTE: file_get_contents adds newline at the end of returned string
    #     $DB['PASSWORD'] = ${if cfg.database.passwordFile != null then "trim(file_get_contents('${cfg.database.passwordFile}'), \"\\r\\n\")" else "''"};
    #     // Schema name. Used for IBM DB2 and PostgreSQL.
    #     $DB['SCHEMA'] = ''';
    #     $ZBX_SERVER = '${cfg.server.address}';
    #     $ZBX_SERVER_PORT = '${toString cfg.server.port}';
    #     $ZBX_SERVER_NAME = ''';
    #     $IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
    #     ${cfg.extraConfig}
    #   '';

    #   settings = {
    #     "listen.owner" = config.services.caddy.user;
    #     "listen.group" = config.services.caddy.group;
    #     "pm" = "dynamic";
    #     "pm.max_children" = 32;
    #     "pm.start_servers" = 2;
    #     "pm.min_spare_servers" = 2;
    #     "pm.max_spare_servers" = 4;
    #     "pm.max_requests" = 500;
    #   };
    # };
  };
}
