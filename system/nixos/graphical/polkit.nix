{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.security.polkit.enable {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "polkit-agent" "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1")
    ];
  };
}
