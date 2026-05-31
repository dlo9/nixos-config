{
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}:
with lib; {
  imports = [
    "${inputs.self}/home"
  ];

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    devenv
    jujutsu
  ];

  # Linux user "pi" collides with atuin's KNOWN_AGENTS list ("pi" = Inflection AI),
  # which causes the interactive TUI to filter out every command via AUTHOR_FILTER_ALL_USER.
  home.sessionVariables.ATUIN_HISTORY_AUTHOR = "david";

  # SSH
  home.file = {
    ".ssh/id_ed25519.pub".text = osConfig.hosts.${osConfig.networking.hostName}.pi-ssh-key.pub;
  };
}
