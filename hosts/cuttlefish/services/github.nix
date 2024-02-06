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
      tokenFile = config.sops.secrets.github-runner.path;
      ephemeral = true;
      url = "https://github.com/dlo9";
    };
  };
}
