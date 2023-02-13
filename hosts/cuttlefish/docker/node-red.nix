{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

#let
#  node-red = pkgs.dockerTools.buildImage {
#    name = "node-red";
#    config = {
#      Cmd = [ "${pkgsLinux.hello}/bin/hello" ];
#    };
#  };
#in
{
  config = {
    virtualisation.oci-containers.containers = {
      node-red = {
        image = "nodered/node-red:2.2.3-12";
        ports = [
          "1880:1880"
        ];

        volumes = [
          "/fast/docker/containers/node-red:/data"
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [
      1880
    ];
  };
}
