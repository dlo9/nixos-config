{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

{
  config = {
    virtualisation.oci-containers.containers = {
      echo = {
        image = "hashicorp/http-echo:0.2.3";
        ports = [
          "5679:5678";
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [
      5678
    ];

    #networking.firewall.allowedUDPPorts = [
    #  3702 # wsdd
    #];
  };
}
