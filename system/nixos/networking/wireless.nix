{
  config,
  lib,
  ...
}:
with lib; {
  sops.secrets.wireless-env.sopsFile = ./secrets.yaml;

  # Configure wpg_supplicant
  networking.wireless = {
    enable = mkDefault true;

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
