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
    services.github-runner = {
      enable = true;
      replace = true;
      ephemeral = true;

      tokenFile = config.sops.secrets.github-runner.path;
      url = "https://github.com/dlo9/wrap";

      extraPackages = with pkgs; [
        nix
        curl
        gnused
        gawk
      ];
    };
  };
}
