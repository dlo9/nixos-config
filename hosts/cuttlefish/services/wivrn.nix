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
      enable = true;
      allowInterfaces = ["enp39s0" "cuttlefish@enp39s0"];

      publish = {
        enable = true;
        userServices = true;
      };
    };

    monado = {
      enable = true;
      # defaultRuntime = true;
    };

    wivrn = {
      enable = true;
      package = pkgs.dlo9.wivrn;
      openFirewall = true;
      defaultRuntime = true;
    };
  };

  # networking.firewall = {
  #   allowedTCPPorts = [9757];
  #   allowedUDPPorts = [9757];
  # };
}
