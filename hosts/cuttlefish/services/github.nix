{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; let
  # Personal accounts can't share self-hosted runners across repos, so we
  # register one ephemeral runner per repo. All run on cuttlefish.
  repos = [
    "wrap"
    "k8s"
    "cuttlefish"
    "resume"
  ];

  mkRunner = repo: {
    name = "${config.networking.hostName}-${repo}";
    value = {
      enable = true;
      package = pkgs.unstable.github-runner;

      nodeRuntimes = [
        "node24"
      ];

      replace = true;
      ephemeral = true;

      tokenFile = config.sops.secrets.github-runner.path;
      url = "https://github.com/dlo9/${repo}";

      # Most builds pull their toolchain from Nix (devenv/flake), so the base
      # set stays small. git/gh are needed by the cuttlefish render/update jobs.
      extraPackages = with pkgs; [
        nix
        curl
        gnused
        gawk
        git
        gh
      ];
    };
  };
in {
  config = {
    services.github-runners = listToAttrs (map mkRunner repos);
  };
}
