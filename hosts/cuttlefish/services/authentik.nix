{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

{
  config = {
    sops.secrets."services/authentik/postgres-password" = {
      sopsFile = config.sys.secrets.hostSecretsFile;
      owner = config.users.users.nix-container1.name;
      group = config.users.users.nix-container1.group;
    };

    sops.secrets."services/authentik/authentik-secret-key" = {
      sopsFile = config.sys.secrets.hostSecretsFile;
      owner = config.users.users.nix-container1.name;
      group = config.users.users.nix-container1.group;
    };

    # virtualisation.oci-containers.containers = {
    #   authentik-postgresql = {
    #     image = "docker.io/library/postgres:12-alpine";
    #     environment = {
    #       # POSTGRES_PASSWORD =
    #       POSTGRES_USER = "authentik";
    #       POSTGRES_DB = "authentik";
    #     };

    #     extraOptions = [
    #       "--restart=unless-stopped"
    #       "--health-cmd=pg_isready -d \${POSTGRES_DB} -U \${POSTGRES_USER}"
    #     ];
    #   };
    # };

    virtualisation.arion = {
      # TODO: doesn't work
      #backend = "podman-socket";
      backend = "docker";

      # https://docs.hercules-ci.com/arion/options
      projects.authentik.settings = {
        docker-compose.raw = {
          secrets = {
            postgres-password.file = config.sops.secrets."services/authentik/postgres-password".path;
            authentik-secret-key.file = config.sops.secrets."services/authentik/authentik-secret-key".path;
          };
        };

        services = {
          postgres.out.service.secrets = [ "postgres-password" ];
          postgres.service = {
            image = "postgres:12-alpine";
            restart = "unless-stopped";
            user = "${toString config.users.users.nix-container1.uid}";

            environment = {
              POSTGRES_USER = "authentik";
              POSTGRES_DB = "authentik";
              POSTGRES_PASSWORD_FILE = "/run/secrets/postgres-password";
            };

            # env_file = [
            #   config.sops.secrets."services/authentik/postgres-password".path
            # ];

            healthcheck = {
              test = [ "pg_isready -d $$\{POSTGRES_DB} -U $$\{POSTGRES_USER}" ];
              # start_period = "20s"; # 0s
              # interval = "30s";
              # retries = "5";  # 3
              # timeout = "5s"; # 30s
            };

            volumes = [
              "/fast/docker/containers/authentik/postgres:/var/lib/postgresql/data"
            ];
          };

          redis.service = {
            image = "redis:alpine";
            restart = "unless-stopped";
            user = "${toString config.users.users.nix-container1.uid}";

            command = "--save 60 1 --loglevel warning"; # TODO: array?

            healthcheck = {
              test = [ "redis-cli ping | grep PONG" ];
              # start_period = "20s"; # 0s
              # interval = "30s";
              # retries = "5";  # 3
              # timeout = "3s"; # 30s
            };

            volumes = [
              "/fast/docker/containers/authentik/redis:/data"
            ];
          };

          server.out.service.secrets = [
            {
              source = "postgres-password";
              # Not actually supported yet: https://github.com/docker/compose/issues/9648
              uid = "1000";
              gid = "1000";
            }
            {
              source = "authentik-secret-key";
              uid = "1000";
              gid = "1000";
            }
          ];

          server.service = {
            image = "ghcr.io/goauthentik/server:2023.3.0";
            restart = "unless-stopped";
            user = "${toString config.users.users.nix-container1.uid}";

            command = "server";

            environment = {
              AUTHENTIK_REDIS__HOST = "redis";
              AUTHENTIK_POSTGRESQL__HOST = "postgres";
              AUTHENTIK_POSTGRESQL__USER = "authentik";
              AUTHENTIK_POSTGRESQL__NAME = "authentik";
              AUTHENTIK_POSTGRESQL__PASSWORD = "file:///run/secrets/postgres-password";
              AUTHENTIK_SECRET_KEY = "file:///run/secrets/authentik-secret-key";
            };

            # TODO
            ports = [
              "9000:9000"
              "9443:9443"
            ];
          };

          worker.out.service.secrets = [
            {
              source = "postgres-password";
              uid = "1000";
              gid = "1000";
            }
            {
              source = "authentik-secret-key";
              uid = "1000";
              gid = "1000";
            }
          ];

          worker.service = {
            image = "ghcr.io/goauthentik/server:2023.3.0";
            restart = "unless-stopped";
            user = "${toString config.users.users.nix-container1.uid}";

            command = "worker";

            environment = {
              AUTHENTIK_REDIS__HOST = "redis";
              AUTHENTIK_POSTGRESQL__HOST = "postgres";
              AUTHENTIK_POSTGRESQL__USER = "authentik";
              AUTHENTIK_POSTGRESQL__NAME = "authentik";
              AUTHENTIK_POSTGRESQL__PASSWORD = "file:///run/secrets/postgres-password";
              AUTHENTIK_SECRET_KEY = "file:///run/secrets/authentik-secret-key";
            };

            volumes = [
              "/fast/docker/containers/authentik/authentik/media:/media"
              "/fast/docker/containers/authentik/authentik/certs:/certs"
              "/fast/docker/containers/authentik/authentik/templates:/templates"
            ];
          };
        };
      };
    };
  };
}
