{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  imports = [
    ./ios.nix
    ./polkit.nix
    ./plasma.nix
  ];

  config = mkIf config.graphical.enable {
    # Allow swaylock
    security.pam.services.swaylock = {};

    # Auto-login since whole-disk encryption is already required
    services.getty.autologinUser = mkDefault config.mainAdmin;

    # Audio
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Links xdg portal for home manager
    # https://home-manager-options.extranix.com/?query=flatpak&release=release-24.05
    environment.pathsToLink = ["/share/xdg-desktop-portal" "/share/applications"];

    services.flatpak.enable = true;

    programs.dconf.enable = true;

    # Desktop portal
    xdg.portal = {
      enable = mkDefault true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];

      # configPackages = with pkgs; [hyprland];
      xdgOpenUsePortal = true;

      config = {
        common.default = ["hyprland" "gtk"];
        preferred.default = ["hyprland" "gtk"];
      };
    };

    # Fonts
    fonts = {
      packages = with pkgs; [
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
          serif = ["NotoSerif Nerd Font" ""];
          sansSerif = ["NotoSans Nerd Font" "DejaVu Sans"];
          monospace = ["NotoSansM Nerd Font Mono"];
          emoji = ["Noto Color Emoji"];
        };
      };
    };

    # Packages
    environment.systemPackages = with pkgs; [
      # Filesystem drivers/utils
      exfatprogs
      ntfs3g

      # Keyring
      libsecret
    ];

    # Printing
    # To add a printer, go to:
    # http://localhost:631/
    services.printing.enable = mkDefault true;
    services.printing.drivers = [
      # See other drivers at https://nixos.wiki/wiki/Printing
      # Brother drivers
      pkgs.brgenml1lpr
      pkgs.brgenml1cupswrapper
    ];

    # Scanning
    services.saned.enable = mkDefault true;
    hardware.sane = {
      enable = mkDefault true;
      drivers.scanSnap.enable = true;
      brscan4 = {
        enable = true;
        netDevices = {
          home = {
            model = "MFC-J480DW";
            nodename = "BRW541379C4810E";
            #ip = "192.168.1.212";
          };
        };
      };
    };

    # Network name services
    services.avahi.enable = mkDefault true;
    services.avahi.nssmdns4 = mkDefault true;

    # Network filesystem mounts
    services.gvfs.enable = mkDefault true;

    # Keyring
    services.gnome.gnome-keyring.enable = mkDefault true;
    programs.seahorse.enable = mkDefault true;
    programs.ssh.enableAskPassword = mkDefault (!config.services.desktopManager.plasma6.enable);
  };
}
