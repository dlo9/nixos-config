{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.gaming.enable {
    programs.steam.enable = mkDefault true;

    environment.systemPackages = with pkgs; [
      heroic
      moonlight-qt
    ];
  };
}
