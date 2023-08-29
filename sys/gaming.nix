{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.sys.gaming = {
    enable = mkEnableOption "gaming programs" // {default = config.sys.graphical.enable;};
  };

  config = mkIf config.sys.gaming.enable {
    programs.steam.enable = true;

    environment.systemPackages = with pkgs; [
      lutris
      gamehub
      moonlight-qt
    ];
  };
}
