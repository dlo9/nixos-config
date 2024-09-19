{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./wivrn/module.nix
  ];

  services = {
    avahi = {
      allowInterfaces = ["enp39s0" "cuttlefish@enp39s0"];
    };

    wivrn = {
      enable = true;
      package = pkgs.dlo9.wivrn;
      openFirewall = true;
      defaultRuntime = true;
      autoStart = true;
    };
  };

  # networking.firewall = {
  #   allowedTCPPorts = [9757];
  #   allowedUDPPorts = [9757];
  # };
}
