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
    ./home/mail.nix
  ];

  home.stateVersion = "22.05";

  # SSH
  home.file = {
    ".ssh/id_ed25519.pub".text = osConfig.hosts.${osConfig.networking.hostName}.david-ssh-key.pub;
  };

  # Deploy targets: forward agent so remote sudo can authenticate
  # via pam_ssh_agent_auth (see system/nixos/networking/ssh.nix).
  # Only enabled on cuttlefish since this is where deploys originate.
  programs.ssh.settings."pavil drywell wyse trident" = {
    ForwardAgent = true;
    AddKeysToAgent = "yes";
  };

  # Load the ssh key into the agent on session start so the forwarded
  # agent is non-empty when deploy-rs sudos on the remote host.
  systemd.user.services.ssh-add-key = {
    Unit = {
      Description = "Load ssh key into ssh-agent";
      After = ["ssh-agent.service"];
      Requires = ["ssh-agent.service"];
    };

    Service = {
      Type = "oneshot";
      Environment = [
        "SSH_AUTH_SOCK=%t/ssh-agent"
        "SSH_ASKPASS_REQUIRE=never"
        "DISPLAY="
      ];
      ExecStart = "${pkgs.openssh}/bin/ssh-add ${config.home.homeDirectory}/.ssh/id_ed25519";
    };

    Install.WantedBy = ["default.target"];
  };

  home.packages = with pkgs; [
    #kdash # kubernetes dashboard
  ];

  programs.zed-editor.installRemoteServer = true;
}
