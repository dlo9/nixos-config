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
    services.nfs.server.enable = true;
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [2049];
  };
}
