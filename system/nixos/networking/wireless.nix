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
    environmentFile = config.sops.secrets.wireless-env.path;
    networks = {
      "?" = {
        psk = "@INTERNET@";
        priority = 10;
      };
      iot.psk = "@IOT@";
      BossAdams.psk = "@BOSS_ADAMS@";
      "pretty fly for a wifi".psk = "@PRETTY_FLY_FOR_A_WIFI@";
      "pretty fly for a wifi-5G".psk = "@PRETTY_FLY_FOR_A_WIFI@";
      qwertyuiop.psk = "@QWERTYUIOP@";
      LGFAK.psk = "@LGFAK@";
      "gh 42".psk = "@GH_42@";
      "Menehune House & Cottage".psk = "@MENEHUNE@";
      BlueWaveHeights.psk = "@BLUE_WAVE_HEIGHTS@";
      "Mountain House".psk = "@MOUNTAIN_HOUSE@";
    };
  };
}
