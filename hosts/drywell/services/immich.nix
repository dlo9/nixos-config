{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; let
in {
  config = {
    virtualisation.oci-containers.containers = {
      immich = {
        image = "ghcr.io/immich-app/immich-server:v1.120.2";

        environment = {
          RXTXRPT = "yes";
          DB_HOSTNAME = "immich-postgres";
          DB_USERNAME = "postgres";
          DB_DATABASE_NAME = "postgres";
          REDIS_HOSTNAME = "immich-redis";
          IMMICH_LOG_LEVEL = "debug";
          PUID = "1000";
          PGID = "1000";
          IMMICH_PORT = "3001";
        };

        environmentFiles = ["/run/secrets/immich"];

        volumes = [
          "/slow/media/photos:/usr/src/app/upload"
        ];

        ports = [ "localhost:3001:3001" ];

        dependsOn = [
          "immich-machine-learning"
          "immich-redis"
          "immich-postgres"
        ];

        extraOptions = [
          "--network=immich"
        ];
      };

      immich-machine-learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:v1.112.1";

        ports = [ "3003" ];

        environment = {
          MACHINE_LEARNING_WORKERS = "1";
          IMMICH_LOG_LEVEL = "debug";
          IMMICH_PORT = "3003";
        };

        volumes = [
          "/services/immich/machine-learning:/cache"
        ];

        extraOptions = [
          "--network=immich"
        ];
      };

      immich-redis = {
        image = "redis:6.2-alpine";
        ports = [ "6379" ];

        extraOptions = [
          "--network=immich"
        ];
      };

      immich-postgres = {
        image = "tensorchord/pgvecto-rs:pg16-v0.2.0";
        ports = [ "5432" ];

        volumes = [
          "/services/immich/postgres:/var/lib/postgresql/data"
        ];

        environmentFiles = ["/run/secrets/immich-postgres"];

        extraOptions = [
          "--network=immich"
        ];
      };
    };
  };
}
