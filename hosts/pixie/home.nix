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

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    which
    openssh
    pkgs.hostname
    dig
    rsync
    mosh

    # SSH start script
    (
      pkgs.writeShellScriptBin "start-sshd" ''
        ${pkgs.openssh}/bin/sshd -f "${config.home.homeDirectory}/.ssh/sshd_config" -D
      ''
    )
  ];

  programs.ssh.matchBlocks."*".user = "david";

  programs.atuin.settings.daemon.enabled = false;

  home.sessionVariables = {
    XDG_RUNTIME_DIR = "/tmp/run";
  };

  programs.fish.shellInit = lib.mkBefore ''
    # nix-on-droid writes the PATH here
    ${pkgs.coreutils}/bin/cat /etc/profile | ${pkgs.babelfish}/bin/babelfish | source

    # Launch services on shell start
    ${config.systemd.user.services.sops-nix.Service.ExecStart}
  '';

  # SSH
  home.file = {
    ".ssh/id_ed25519.pub".text = osConfig.hosts.${hostname}.host-ssh-key.pub;

    ".ssh/authorized_keys".text = ''
      ${osConfig.hosts.cuttlefish.david-ssh-key.pub}
      ${osConfig.hosts.pavil.david-ssh-key.pub}
      ${osConfig.hosts.bitwarden.ssh-key.pub}
    '';

    ".ssh/sshd_config".text = ''
      HostKey ${config.home.homeDirectory}/.ssh/id_ed25519
      Port 8022
    '';
  };
}
