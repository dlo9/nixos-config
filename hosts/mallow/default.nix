{ pkgs
, lib
, inputs
, ...
}:
with lib; {
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  security.pki.certificateFiles = [
    ./ca-certificates.crt
  ];

  homebrew = {
    enable = true;

    brews = [
      "kafka"
      "pyenv"
      "jenv"
    ];

    casks = [
      "docker"
      "firefox"
      "google-drive"
      "jdk-mission-control"
      "nosqlbooster-for-mongodb"
      "sensiblesidebuttons"
    ];
  };

  services.yabai = {
    enable = true;

    # https://github.com/koekeishiya/yabai/wiki/Configuration#configuration-file
    config = {
      # bsp or float (default: bsp)
      layout = "bsp";

      # Set all padding and gaps to 20pt (default: 0)
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 10;
      right_padding = 10;
      window_gap = 10;

      focus_follows_mouse = "autoraise";
      mouse_follows_focus = "on";

      # Mouse actions
      mouse_modifier = "alt";
      mouse_action1 = "move";
      mouse_action2 = "resize";

      # Window borders
      window_border = "on";
      window_border_width = 1;
      window_border_radius = 13;
      window_border_blur = "off";
      active_window_border_color = "0xFFB928B9";
      normal_window_border_color = "0x00B9B9B9";

      # Window creation
      window_origin_display = "focused";
    };

    extraConfig = ''
      # Window rules
      yabai -m rule --add label=FloatSystemPreferences app="System Preferences" manage=off
      yabai -m rule --add label=FloatVPN app="Cisco AnyConnect Secure Mobility Client" manage=off
      yabai -m rule --add label=FloatJAMF app="Jamf Connect Sync" title="Sign In" manage=off
      yabai -m rule --add label=FloatTreeTabConfirmation app="Firefox" title="Close.*tabs?" manage=off
      yabai -m rule --add label=FloatIntelliJIntro app="IntelliJ IDEA" title="Welcome to IntelliJ IDEA" manage=off
      yabai -m rule --add label=FloatColorMeter app="Digital Color Meter" manage=off

      # Steam popups are especially annoying, and mouse focus doesn't seem to know the window name before acting.
      # To work around this, mouse foxus is disabled by default until the window is known to not be Steam-related
      yabai -m rule --add label=FloatSteam app="Steam" manage=off
      yabai -m rule --add label=FocusAll app!="Steam" mouse_follows_focus=on

      # Kill iTunes when I press `play` and forget that my headphones are still connected
      yabai -m signal --add event=window_created app=iTunes title=iTunes action="killall iTunes"
    '';
  };

  services.spacebar = {
    enable = true;
    package = pkgs.spacebar;
    # config = {};
    extraConfig = ''
      #!/usr/bin/env sh

      spacebar -m config position             top
      spacebar -m config height               26
      spacebar -m config title                on
      spacebar -m config spaces               on
      spacebar -m config clock                on
      spacebar -m config power                on
      spacebar -m config padding_left         20
      spacebar -m config padding_right        20
      spacebar -m config spacing_left         25
      spacebar -m config spacing_right        15
      spacebar -m config text_font            "NotoSansM Nerd Font Mono:Bold:12.0"
      spacebar -m config icon_font            "NotoSansM Nerd Font Mono:Solid:12.0"
      spacebar -m config background_color     0xff202020
      spacebar -m config foreground_color     0xffa8a8a8
      spacebar -m config space_icon_color     0xff458588
      spacebar -m config power_icon_color     0xffcd950c
      spacebar -m config battery_icon_color   0xffd75f5f
      spacebar -m config dnd_icon_color       0xffa8a8a8
      spacebar -m config clock_icon_color     0xffa8a8a8
      spacebar -m config power_icon_strip      
      spacebar -m config space_icon_strip     I II III IV V VI VII VIII IX X
      spacebar -m config space_icon           
      spacebar -m config clock_icon           
      spacebar -m config dnd_icon             
      spacebar -m config clock_format         "%d/%m/%y %R"
      spacebar -m config right_shell          on
      spacebar -m config right_shell_icon     
      spacebar -m config right_shell_command  "whoami"

      echo "spacebar configuration loaded.."
    '';
  };

  services.skhd = {
    # Don't forget to disable "Secure Keyboard Entry" by opening the terminal application
    enable = true;
    skhdConfig = ''
      # To debug "secure keyboard entry" error:
      # https://github.com/koekeishiya/skhd/issues/48
      # ioreg -l -w 0 | perl -nle 'print $1 if /"kCGSSessionSecureInputPID"=(\d+)/' | uniq | xargs -I{} ps -p {} -o comm=

      # Focus window
      alt - left : yabai -m window --focus west || yabai -m display --focus west
      alt - right : yabai -m window --focus east || yabai -m display --focus east
      alt - up : yabai -m window --focus north || yabai -m display --focus north
      alt - down : yabai -m window --focus south || yabai -m display --focus south

      # Move managed window
      alt - space : yabai -m window --toggle split
      alt + shift - left : yabai -m window --swap west || (yabai -m window --display west && yabai -m display --focus west)
      alt + shift - right : yabai -m window --swap east || (yabai -m window --display east && yabai -m display --focus east)
      alt + shift - up : yabai -m window --swap north || (yabai -m window --display north && yabai -m display --focus north)
      alt + shift - down : yabai -m window --swap south || (yabai -m window --display south && yabai -m display --focus south)

      # Fullscreen
      alt - f : yabai -m window --toggle native-fullscreen
      #alt - f : yabai -m window --toggle zoom-fullscreen

      # Close
      alt + shift - q : yabai -m window --close

      # Terminal
      alt - return : /Applications/Alacritty.app/Contents/MacOS/alacritty

      # Resizing
      alt + ctrl - left : yabai -m window --resize left:-100:0 || yabai -m window --resize right:-100:0
      alt + ctrl - right : yabai -m window --resize right:100:0 || yabai -m window --resize left:100:0
      alt + ctrl - up : yabai -m window --resize top:0:-100 || yabai -m window --resize bottom:0:-100
      alt + ctrl - down : yabai -m window --resize bottom:0:100 || yabai -m window --resize top:0:100

      # Toggle focus & center window
      alt + shift - space : yabai -m window --toggle float && yabai -m window --grid 4:4:1:1:2:2 && yabai -m window --focus

      # Focus monitor
      alt - 1 : yabai -m display --focus 1
      alt - 2 : yabai -m display --focus 2
      alt - 3 : yabai -m display --focus 3

      # Send window to monitor
      alt + shift - 1 : yabai -m window --display 1 && yabai -m display --focus 1
      alt + shift - 2 : yabai -m window --display 2 && yabai -m display --focus 2
      alt + shift - 3 : yabai -m window --display 3 && yabai -m display --focus 3

      # Set split direction
      alt - v : yabai -m window --insert south
      alt - h : yabai -m window --insert east

      # Reset split ratio
      alt + ctrl - r : yabai -m window --ratio abs:0.5

      # Restart yabai
      alt + shift - r : pkill yabai; yabai &

      # Enable/disable yabai tiling
      alt + shift - e : if [ "$(yabai -m config layout)" == "bsp" ]; then yabai -m config layout float; else yabai -m config layout bsp; fi

      # Toggle dock visibility
      cmd - d: osascript -e 'tell application "System Events" to set the autohide of the dock preferences to not (get the autohide of the dock preferences)'
    '';
  };

  home-manager.users.dorchard = {
    xdg.configFile."wrap.yaml" = {
      text = mkForce null;
      source = ./wrap.yaml;
    };

    home.packages = with pkgs; [
      kubectl

      # gcloud components install gke-gcloud-auth-plugin
      (google-cloud-sdk.withExtraComponents (with google-cloud-sdk.components; [
        gke-gcloud-auth-plugin
      ]))

      rnix-lsp # Nix language server

      # Use a new launcher since spotlight doesn't find nix GUI applications:
      # https://github.com/nix-community/home-manager/issues/1341
      raycast

      # Fonts
      # Nerdfonts is huge, so only install specific fonts
      # https://github.com/NixOS/nixpkgs/blob/nixos-22.05/pkgs/data/fonts/nerdfonts/shas.nix
      (nerdfonts.override {
        fonts = [
          "Noto"
        ];
      })

      noto-fonts-emoji

      # Java tools
      visualvm
      jetbrains.idea-ultimate
      gradle
      groovy
      google-java-format
      maven

      # Golang
      go
      protobuf

      # Kafka
      kcat
      kafkactl

      # Python
      # python38
      # python39
      # python310Full
      # python311
      # python312

      # Shell tools
      gnused
      coreutils-prefixed
      gawk

      # Bazel
      bazelisk
      bazel-buildtools

      # Other tools
      ansible
      # nodejs
      mongosh
      openldap
      terraform

      # Window manager/hotkeys
      skhd

      # Business apps
      slack
      zoom-us
    ];

    home.sessionVariables = {
      # Java versions
      JAVA_HOME = "${pkgs.jdk}/lib/openjdk";
      JAVA_8_HOME = "${pkgs.jdk8}/lib/openjdk";
      JAVA_11_HOME = "${pkgs.jdk11}/lib/openjdk";
    };

    programs.ssh = {
      enable = true;
      matchBlocks."d1lrtcappprd?".extraOptions = {
        HostKeyAlgorithms = "+ssh-rsa";
        PubkeyAcceptedAlgorithms = "+ssh-rsa";
      };
    };
  };
}
