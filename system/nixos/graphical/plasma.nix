{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  enabled = config.services.desktopManager.plasma6.enable;

  # https://github.com/sddm/sddm/issues/1768
  sddm = pkgs.kdePackages.sddm.override {
    runCommand = (name: env: buildCommand:
      pkgs.runCommand name env (buildCommand + ''
        # Replace the link with a real copy
        mv "$out/share" "$out/share.link"
        cp -Lr "$out/share.link" "$out/share"
        rm "$out/share.link"

        for f in $out/bin/*; do
          wrapProgram "$f" --set SHELL ${pkgs.bash}
        done

        chmod u+w \
          $out/share \
          $out/share/sddm \
          $out/share/sddm/scripts

        for f in $out/share/sddm/scripts/*; do
          wrapProgram "$f" --set SHELL ${pkgs.bash}
        done
      '')
    );
  };
in {
  services.displayManager = {
    enable = mkDefault enabled;
    autoLogin.user = mkDefault config.mainAdmin;

    sddm = {
      enable = mkDefault enabled;
      wayland.enable = mkDefault enabled; # Use waycheck to check wayland features
      autoLogin.relogin = mkDefault true;
      #package = mkForce sddm;
    };
  };
}
