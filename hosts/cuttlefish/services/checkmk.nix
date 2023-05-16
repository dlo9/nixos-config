{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

{
  imports = [
    inputs.check_mk_agent.nixosModules.check_mk_agent
  ];

  config = {
    services.check_mk_agent = {
      enable = true;
      bind = "0.0.0.0";
      openFirewall = true;
      package = pkgs.check_mk_agent.override {
        enablePluginSmart = true;
        enablePluginDocker = true;
      };
    };

    sops.secrets."services/checkmk/env" = {
      sopsFile = config.sys.secrets.hostSecretsFile;
    };

    # https://docs.checkmk.com/latest/en/introduction_docker.html
    # https://docs.checkmk.com/latest/en/managing_docker.html
    virtualisation.oci-containers.containers.checkmk = {
      image = "checkmk/check-mk-raw:2.1.0-latest";
      ports = [
        "10001:5000" # Web server
        "10002:8000" # Agent Receiver
      ];

      volumes = [
        "/fast/docker/containers/checkmk:/omd/sites"
        "/etc/localtime:/etc/localtime:ro"
      ];

      environment = {
        CMK_SITE_ID = "cuttlefish";
      };

      environmentFiles = [
        config.sops.secrets."services/checkmk/env".path
      ];
    };

    # networking.firewall.allowedTCPPorts = [
    #   10001
    #   10002
    # ];

    # Caddy
    # reverseProxies = { checkmk = "http://localhost:5000"; };

    services.caddy.virtualHosts.checkmk = {
      useACMEHost = "sigpanic.com";
      serverAliases = [ "checkmk.sigpanic.com" ];
      extraConfig = ''
        reverse_proxy http://localhost:10001
      '';
    };
  };
}
