{
  config,
  lib,
  ...
}:
with lib; {
  services.tailscale.enable = mkDefault true;

  # sops.secrets.tailscale-auth-key = {
  #   sopsFile = config.secrets.hostSecretsFile;
  # };

  # systemd.services.tailscale-anthenticate = {
  #   enable = mkDefault false;

  #   wantedBy = ["multi-user.target"];

  #   script = ''
  #     tailscale up --auth-key "file:${config.sops.secrets.tailscale-auth-key.path}"
  #   '';
  # };

  systemd.network = {
    enable = mkDefault true;

    networks."50-wg0" = {
      matchConfig.Name = "wg0";
      address = ["100.64.21.154/32"];
      domains = ["~."];
      dns = ["198.18.0.1" "198.18.0.2"];

      networkConfig = {
        DNSDefaultRoute = true;
      };

      linkConfig = {
        ActivationPolicy = "manual";
      };

      routingPolicyRules =
        [
          {
            # Route everything else to wireguard
            Priority = 10;
            InvertRule = true;
            Family = "both";

            # Mark this rule so that it doesn't match itself
            Table = 51820;
            FirewallMark = 51820; # Mark
          }
        ]
        ++ (builtins.map (to: {
            Priority = 9;
            To = to;
          }) [
            # Allow Tailscale
            "100.64.0.0/10"

            # Allow private ranges
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
          ]);
    };

    netdevs."50-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
      };

      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets.wireguard.path;
        RouteTable = 51820;
        FirewallMark = 51820;
      };

      wireguardPeers = [
        {
          PublicKey = "KgTUh3KLijVluDvNpzDCJJfrJ7EyLzYLmdHCksG4sRg=";
          AllowedIPs = ["0.0.0.0/0"];
          Endpoint = "45.38.15.94:51820";
        }
      ];
    };
  };
}
