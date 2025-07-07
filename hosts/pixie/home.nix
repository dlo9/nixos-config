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
        echo "Starting ssh in the foreground"
        ${pkgs.openssh}/bin/sshd -f ~/.ssh/sshd_config -D
      ''
    )
  ];

  programs.ssh.matchBlocks."*".user = "david";

  programs.atuin.settings.daemon.enabled = false;

  home.sessionVariables = {
    XDG_RUNTIME_DIR = "/tmp/run";
  };

  # Disable this since `id` isn't in home-manager's path, which
  # causes issues when setting up TMUX_TMPDIR
  programs.tmux.secureSocket = false;

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
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      AuthorizedKeysFile ~/.ssh/authorized_keys
      HostKey ~/.ssh/id_ed25519
      Port 8022
      Subsystem sftp ${pkgs.openssh}/libexec/sftp-server
    '';
  };
}
