{ config, lib, ... }:

with lib; {
  services.avahi = {
    enable = true;
    allowInterfaces = [ "enp39s0" "cuttlefish@enp39s0" ];

    publish = {
      enable = true;
      userServices = true;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [9757];
    allowedUDPPorts = [9757];
  };
}
