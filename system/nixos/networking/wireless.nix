{
  config,
  lib,
  ...
}:
with lib; let
  useNM = config.networking.networkmanager.enable;

  # Single source of truth for wifi networks. Routed to either wpa_supplicant
  # or NetworkManager below, depending on which backend is enabled.
  networks = {
    "?" = {
      pskRaw = "ext:INTERNET";
      priority = 10;
    };

    #iot.pskRaw = "ext:IOT";
    BossAdams.pskRaw = "ext:BOSS_ADAMS";
    "pretty fly for a wifi".pskRaw = "ext:PRETTY_FLY_FOR_A_WIFI";
    "pretty fly for a wifi-5G".pskRaw = "ext:PRETTY_FLY_FOR_A_WIFI";
    qwertyuiop.pskRaw = "ext:QWERTYUIOP";
    LGFAK.pskRaw = "ext:LGFAK";
    "gh 42".pskRaw = "ext:GH_42";
    "Menehune House & Cottage".pskRaw = "ext:MENEHUNE";
    BlueWaveHeights.pskRaw = "ext:BLUE_WAVE_HEIGHTS";
    "Mountain House".pskRaw = "ext:MOUNTAIN_HOUSE";
    "interxfi".pskRaw = "ext:INTERCHANGE";
  };

  # Normalize network attrs so missing fields don't break the NM mapping
  normalizedNetworks =
    builtins.mapAttrs (_: settings: {
      pskRaw = settings.pskRaw or null;
      priority = settings.priority or null;
    })
    networks;
in {
  sops.secrets.wireless-env = {
    sopsFile = ./secrets.yaml;
    path = "/etc/wpa_supplicant/secrets";
    owner = "wpa_supplicant";
    group = "wpa_supplicant";
  };

  # Configure wpa_supplicant when NetworkManager is not in charge
  networking.wireless = mkIf (!useNM) {
    enable = mkDefault true;
    userControlled = mkDefault true;
    allowAuxiliaryImperativeNetworks = mkDefault true;
    secretsFile = config.sops.secrets.wireless-env.path;
    inherit networks;
  };

  # Configure NetworkManager when it is enabled
  networking.networkmanager.ensureProfiles = mkIf useNM {
    environmentFiles = [config.sops.secrets.wireless-env.path];

    # Available settings: man nm-settings-nmcli
    profiles = builtins.mapAttrs (ssid: settings:
      builtins.foldl' lib.recursiveUpdate {} [
        {
          connection = {
            id = ssid;
            type = "wifi";
          };

          wifi.ssid = ssid;
        }

        (optionalAttrs (settings.pskRaw != null) {
          wifi-security = {
            psk = builtins.replaceStrings ["ext:"] ["$"] settings.pskRaw;
            key-mgmt = "wpa-psk";
          };
        })

        (optionalAttrs (settings.priority != null) {
          connection.autoconnect-priority = settings.priority;
        })
      ])
    normalizedNetworks;
  };
}
