# TODO: https://www.reddit.com/r/NixOS/comments/6gh32h/suggestions_for_organizing_nixos_configs/
# Search for config options at: https://search.nixos.org/options?channel=21.11
{ config, pkgs, ... }:

{
  imports = [
    ./system.nix
    ./polkit.nix
  ];

  # Secrets
  # This will add secrets.yml to the nix store

  # You can avoid this by adding a string to the full path instead, i.e.
  # sops.defaultSopsFile = "/root/.sops/secrets/example.yaml";
  sops.defaultSopsFile = ./secrets/secrets.yaml;

  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    /home/david/.ssh/id_ed25519
  ];

  # This is using an age key that is expected to already be in the filesystem
  #sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.keyFile = "/home/david/.config/sops/age/keys.txt";

  # This will generate a new key if the key specified above does not exist
  #sops.age.generateKey = true;

  # This is the actual specification of the secrets.
  sops.secrets."wireless-env" = {};

  networking.enableIPv6 = false;

  # Enable flake support
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot.loader.grub.configurationLimit = 20;
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.mirroredBoots = [
    { devices = ["nodev"]; efiSysMountPoint = "/boot/efi"; path = "/boot/efi/EFI"; }
  ];

  # Should be random for each host to ensure pool doesn't replace root on a different host
  # tr -dc 0-9a-f < /dev/urandom | head -c 8
  networking = {
    hostName = "pavil";
    hostId = "fa305d4a"; 
    wireless = {
      enable = true;
      userControlled.enable = true;
      environmentFile = "/run/secrets/wireless-env";
      networks = {
        BossAdams.psk = "@BOSS_ADAMS@";
        "pretty fly for a wifi".psk = "@PRETTY_FLY_FOR_A_WIFI@";
        qwertyuiop.psk = "@QWERTYUIOP@";
      };
    };
  };

  hardware.opengl.enable = true;

  # Must load network module on boot
  # lspci -v | grep -iA8 'network\|ethernet'
  #boot.initrd.availableKernelModules = [ "iwlwifi" ];
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
  #boot.kernelPackages = pkgs.linuxKernel.kernels.linux_zen;
  #boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelPackages = pkgs.linuxPackages_testing;
  environment.systemPackages = with pkgs; [
    starship
    zoxide
    lshw
    alacritty
    ly
    gparted
    cargo
    clang
    git
    firefox-wayland
    yadm

    # sgdisk
    gptfdisk

    qutebrowser

    # NixOS secrets
    sops
    ssh-to-age
  ];

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "DejaVuSansMono" ]; })
  ];

  hardware.pulseaudio.enable = true;
  programs.xwayland.enable = true;
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export _JAVA_AWT_WM_NONREPARENTING=1
      export MOZ_ENABLE_WAYLAND=1
    '';
    extraPackages = with pkgs; [
      # Core
      swaylock
      swayidle
      swaybg
      waybar

      # Clipboard
      wl-clipboard

      # Notifications
      mako

      # Shell
      alacritty
      #fish

      # Menus and application selection
      wofi
      dex
      #dmenu

      brightnessctl
      pavucontrol
    ];
  };

  # Auto-login since whole-disk encryption is already required
  programs.fish.enable = true;
  services.getty.autologinUser = "david";
  environment.loginShellInit = ''
    if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec sway
    fi
  '';

  custom.polkit = {
    enable = true;
    user = "david";
  };
}

