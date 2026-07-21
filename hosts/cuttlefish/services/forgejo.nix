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
    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;

      instances.cuttlefish = {
        enable = true;
        name = config.networking.hostName;
        url = "https://git.sigpanic.com";

        tokenFile = config.sops.secrets.forgejo-runner.path;

        # `<label>:host` runs on cuttlefish directly (like the github runners);
        # `<label>:docker://<image>` runs in a container on the host Docker
        # daemon
        labels = [
          "native:host"
          "ubuntu-latest:docker://catthehacker/ubuntu:act-22.04"
          "self-hosted:docker://catthehacker/ubuntu:act-22.04"
        ];

        # Available to native:host jobs
        hostPackages = with pkgs; [
          bash
          coreutils
          curl
          devenv
          gawk
          git
          gh
          gnused
          nix
          nodejs
        ];

        settings = {
          # Max concurrent jobs on this runner.
          runner.capacity = 8;

          # Pin actions cache port, so that we can open it to action containers
          cache = {
            enabled = true;
            proxy_port = 34567;
          };
        };
      };
    };

    # Allow access to the actions cache
    networking.firewall.interfaces."br-+".allowedTCPPorts = [
      config.services.gitea-actions-runner.instances.cuttlefish.settings.cache.proxy_port
    ];

    # Run the runner as a static system user instead of the module's default
    # DynamicUser. DynamicUser mounts the StateDirectory (the job workspace) with
    # an idmapped, `noexec` mount, which blocks executing freshly built binaries
    # and composite-action scripts from the workspace on `native` jobs. A static
    # user's StateDirectory is a plain, exec-capable directory.
    users.users.gitea-runner = {
      isSystemUser = true;
      group = "gitea-runner";
      home = "/var/lib/gitea-runner";
    };
    users.groups.gitea-runner = {};

    systemd.services.gitea-runner-cuttlefish.serviceConfig = {
      DynamicUser = mkForce false;
      Group = "gitea-runner";

      # DynamicUser implied this hardening; re-add it explicitly so dropping
      # DynamicUser doesn't widen the runner's host access. None of these add
      # noexec to the StateDirectory — that came only from DynamicUser's idmapped
      # mount, which is now gone. (SupplementaryGroups=docker, set by the module,
      # is preserved, so container jobs still reach the Docker socket.)
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      PrivateTmp = true;
      NoNewPrivileges = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
    };
  };
}
