{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; let
  composeService = compose: let
    project = compose.name;
    file = builtins.toFile "docker-compose-${project}.yaml" (lib.generators.toYAML {} compose);
  in {
    ${project} = {
      enable = true;
      description = "Docker-compose service for ${project}";
      wantedBy = ["multi-user.target"];
      restartTriggers = [file];

      path = with pkgs; [
        podman
      ];

      serviceConfig = let
        podmanCompose = "${pkgs.podman-compose}/bin/podman-compose -p ${project} -f ${file}";
        podman = "${pkgs.podman}/bin/podman";
      in {
        Type = "simple";
        ExecStartPre = [
          "${podmanCompose} up --no-start "
          "${podman} pod start pod_${project}"
        ];

        ExecStart = "${podmanCompose} wait";
        ExecStop = "${podman} pod stop pod_${project}";
      };
    };
  };
in {
  systemd.services = composeService {
    name = "immich";

    services = {
      immich = {
        image = "ghcr.io/immich-app/immich-server:v1.120.2";

        environment = {
          TZ = "America/Los_Angeles";
          DB_HOSTNAME = "postgres";
          DB_USERNAME = "postgres";
          DB_DATABASE_NAME = "postgres";
          REDIS_HOSTNAME = "redis";
          IMMICH_LOG_LEVEL = "debug";
          PUID = 1000;
          PGID = 1000;
          IMMICH_PORT = 3001;
        };

        env_file = [config.sops.secrets.immich.path];
        ports = ["127.0.0.1:3001:3001"];
        volumes = ["/slow/media/photos:/usr/src/app/upload"];
        devices = ["/dev/dri:/dev/dri"]; # Quicksync
        restart = "always";
        depends_on = [
          "redis"
          "machine-learning"
          "postgres"
        ];
      };

      machine-learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:v1.112.0-openvino";

        environment = {
          TZ = "America/Los_Angeles";
          IMMICH_LOG_LEVEL = "debug";
          IMMICH_PORT = 3003;
          MACHINE_LEARNING_WORKERS = 1;
        };

        ports = ["3003"];

        volumes = [
          "/services/immich/machine-learning:/cache"
          "/dev/bus/usb:/dev/bus/usb" # Openvino
        ];

        device_cgroup_rules = ["c 189:* rmw"];
        devices = ["/dev/dri:/dev/dri"];
      };

      redis = {
        image = "redis:6.2-alpine";
        environment.TZ = "America/Los_Angeles";
        ports = ["6379"];
      };

      postgres = {
        image = "tensorchord/pgvecto-rs:pg16-v0.2.0";
        environment.TZ = "America/Los_Angeles";
        env_file = [config.sops.secrets.immich-postgres.path];
        ports = ["5432"];
        volumes = ["/services/immich/postgres:/var/lib/postgresql/data"];
      };
    };
  };
}
