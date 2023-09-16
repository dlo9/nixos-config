{
  config,
  lib,
  ...
}:
with lib; {
  services.tailscale.enable = mkDefault true;

  sops.secrets.tailscale-auth-key = {
    sopsFile = config.secrets.hostSecretsFile;
  };

  systemd.services.tailscale-anthenticate = {
    enable = mkDefault false;

    wantedBy = ["multi-user.target"];

    script = ''
      tailscale up --auth-key "file:${config.sops.secrets.tailscale-auth-key.path}"
    '';
  };
}
