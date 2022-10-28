{ config, pkgs, lib, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.graphical;
in
{
  imports = [
    ./polkit.nix
  ];

  options.sys.graphical = {
    enable = mkEnableOption "graphical shell" // { default = true; };
  };

  config = mkIf cfg.enable {
    # Allow swaylock
    security.pam.services.swaylock = { };

    # Auto-login since whole-disk encryption is already required
    services.getty.autologinUser = "${sysCfg.user}";
    environment.loginShellInit = mkDefault ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec sway
      fi
    '';

    # Audio
    hardware.pulseaudio.enable = true;

    # Fonts
    fonts = {
      fonts = with pkgs; [
        # Nerdfonts is huge, so only install specific fonts
        # https://github.com/NixOS/nixpkgs/blob/nixos-22.05/pkgs/data/fonts/nerdfonts/shas.nix
        (nerdfonts.override {
          fonts = [
            "Noto"
          ];
        })

        noto-fonts-emoji
      ];

      fontconfig = {
        defaultFonts = {
          serif = [ "NotoSerif Nerd Font" "" ];
          sansSerif = [ "NotoSans Nerd Font" "DejaVu Sans" ];
          monospace = [ "Noto Nerd Font Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };

    # Packages
    environment.systemPackages = with pkgs; [
      # System utils
      gparted # Partitioning

      # Web browsers
      qutebrowser
      firefox-wayland
      chromium

      # Key tester
      wev

      mpv
      okular
      zathura
    ];

    # Location services
    services.geoclue2 = {
      enable = true;

      appConfig = {
        "gammastep" = {
          isAllowed = true;
          isSystem = false;
          users = [ "1000" ];
        };
      };
    };

    # Printing
    # To add a printer, go to:
    # http://localhost:631/
    services.printing.enable = true;
    services.printing.drivers = [
      # See other drivers at https://nixos.wiki/wiki/Printing
      # Brother drivers
      pkgs.brgenml1lpr
      pkgs.brgenml1cupswrapper
    ];

    services.avahi.enable = true;
    services.avahi.nssmdns = true;

    # Add GVFS for samba mounts in file manager
    #services.gvfs.enable = true;
    services.gvfs = {
      enable = true;
      package = lib.mkForce pkgs.gnome.gvfs;
    };

    services.gnome.gnome-keyring.enable = true;
  };
}
