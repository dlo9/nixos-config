{lib, ...}:
with lib; {
  options = {
    developer-tools.enable = mkEnableOption "developer tools";
    graphical.enable = mkEnableOption "graphical programs";
  };
}
