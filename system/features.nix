{lib, ...}:
with lib; {
  options = {
    developer-tools.enable = mkEnableOption "developer tools";
    graphical.enable = mkEnableOption "graphical programs";

    # Declared here rather than in the NixOS module so the home side can read
    # it on any platform. See system/nixos/graphical/dms.nix.
    dms.greeter.enable = mkEnableOption "the DankMaterialShell greetd greeter";
  };
}
