{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.gaming.enable = mkEnableOption "gaming programs";

  config = mkIf config.gaming.enable {
    programs.steam.enable = mkDefault true;

    environment.systemPackages = with pkgs; [
      #heroic
      moonlight-qt
    ];
  };
}
