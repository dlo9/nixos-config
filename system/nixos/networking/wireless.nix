{
  config,
  lib,
  ...
}:
with lib; {
  sops.secrets.wireless-env.sopsFile = ./secrets.yaml;

  networking.networkmanager.ensureProfiles = {
    # Configure networkmanager secrets
    environmentFiles = [ config.sops.secrets.wireless-env.path ];

    # Available settings: man nm-settings-nmcli
    # Convert wifi settings into network-manager profiles
    profiles = builtins.mapAttrs (ssid: settings: builtins.foldl' lib.recursiveUpdate {} [
      # Basic wifi settings
      {
        connection = {
          id = ssid;
          type = "wifi";
        };

        wifi.ssid = ssid;
      }

      # Wifi password
      (optionalAttrs (settings.pskRaw != null) {
        wifi-security = {
          psk = builtins.replaceStrings ["ext:"] ["$"] settings.pskRaw;
          key-mgmt = "wpa-psk";
        };
      })

      (optionalAttrs (settings.priority != null) {
        connection.autoconnect-priority = settings.priority;
      })
    ]) config.networking.wireless.networks;
  };

  # Configure wpa_supplicant
  networking.wireless = {
    enable = mkDefault (!config.networking.networkmanager.enable);

    # Enable wpa_gui
    userControlled.enable = mkDefault true;
    secretsFile = config.sops.secrets.wireless-env.path;
    networks = {
      "?" = {
        pskRaw = "ext:INTERNET";
        priority = 10;
      };
      iot.pskRaw = "ext:IOT";
      BossAdams.pskRaw = "ext:BOSS_ADAMS";
      "pretty fly for a wifi".pskRaw = "ext:PRETTY_FLY_FOR_A_WIFI";
      "pretty fly for a wifi-5G".pskRaw = "ext:PRETTY_FLY_FOR_A_WIFI";
      qwertyuiop.pskRaw = "ext:QWERTYUIOP";
      LGFAK.pskRaw = "ext:LGFAK";
      "gh 42".pskRaw = "ext:GH_42";
      "Menehune House & Cottage".pskRaw = "ext:MENEHUNE";
      BlueWaveHeights.pskRaw = "ext:BLUE_WAVE_HEIGHTS";
      "Mountain House".pskRaw = "ext:MOUNTAIN_HOUSE";
    };
  };
}
