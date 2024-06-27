{
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
  hostname,
  ...
}:
with lib; {
  imports = [
    "${inputs.self}/home"
    "${inputs.self}/home/secrets.nix"
  ];

  home.packages = with pkgs; [
    which
    openssh
  ];

  programs.ssh = {
    enable = true;
    matchBlocks."*".user = "david";
  };

  programs.atuin.settings.daemon.enabled = false;

  home.sessionVariables = {
    XDG_RUNTIME_DIR = "/tmp/run";
  };

  # Launch services on shell start
  programs.fish.interactiveShellInit = ''
    ${config.systemd.user.services.sops-nix.Service.ExecStart}
  '';

  # SSH
  home.file = {
    ".ssh/id_ed25519.pub".text = osConfig.hosts.${hostname}.host-ssh-key.pub;
  };
}
