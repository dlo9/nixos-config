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
    runCommand = (
      name: env: buildCommand:
        pkgs.runCommand name env (buildCommand
          + ''
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
    # Only claim the display-manager slot when plasma is on: an unconditional
    # `mkDefault false` collides with greetd's `mkDefault true` -- same
    # priority, so an eval error rather than an override.
    enable = mkIf enabled (mkDefault true);

    # Unconditional: the DMS greeter turns this into greetd's
    # `initial_session`, which keeps boot going straight to the desktop.
    autoLogin.user = mkDefault config.mainAdmin;

    sddm = {
      enable = mkDefault enabled;
      wayland.enable = mkDefault enabled; # Use waycheck to check wayland features
      autoLogin.relogin = mkDefault true;
      #package = mkForce sddm;
    };
  };
}
