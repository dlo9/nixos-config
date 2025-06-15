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

  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    which
    openssh
    pkgs.hostname
    bind # "host" binary
    rsync
    mosh

    # Needed for home-manager script
    coreutils
  ];

  programs.ssh.matchBlocks."*".user = "david";

  programs.atuin.settings.daemon.enabled = false;

  home.sessionVariables = {
    XDG_RUNTIME_DIR = "/tmp/run";
  };

  programs.fish.shellInit = lib.mkBefore ''
    # nix-on-droid writes the PATH here
    #source /etc/profile

    ${pkgs.coreutils}/bin/cat /etc/profile | ${pkgs.babelfish}/bin/babelfish | source

    # Launch services on shell start
    ${config.systemd.user.services.sops-nix.Service.ExecStart}

    # TODO: start SSH
  '';

  # SSH
  home.file = {
    ".ssh/id_ed25519.pub".text = osConfig.hosts.${hostname}.host-ssh-key.pub;
  };
}
