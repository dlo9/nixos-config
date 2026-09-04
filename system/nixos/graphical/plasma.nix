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
    # Only claim the display-manager slot when plasma is actually on. Asserting
    # `mkDefault false` unconditionally collides with any other display manager
    # module -- greetd sets this to `mkDefault true`, which is the same
    # priority, so the two are an eval error rather than an override.
    enable = mkIf enabled (mkDefault true);

    # Left unconditional: the DMS greeter turns this into a greetd
    # `initial_session`, which is what keeps boot going straight to the desktop
    # instead of prompting.
    autoLogin.user = mkDefault config.mainAdmin;

    sddm = {
      enable = mkDefault enabled;
      wayland.enable = mkDefault enabled; # Use waycheck to check wayland features
      autoLogin.relogin = mkDefault true;
      #package = mkForce sddm;
    };
  };
}
