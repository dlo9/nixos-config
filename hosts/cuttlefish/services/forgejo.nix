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
  };
}
