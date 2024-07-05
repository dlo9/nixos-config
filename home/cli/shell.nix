{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  programs = {
    fish = {
      enable = mkDefault true;

      shellInit = ''
        # Unexport Homemanager variable
        # This variable is exported, but other guards (e.g. /etc/profile) aren't. When jumping
        # onto a box with mosh this can cause global variables to override user ones. By unexporting,
        # we source variables every time per shell. This matches fish's config guard as well.
        set -gu __HM_SESS_VARS_SOURCED $__HM_SESS_VARS_SOURCED
      '';

      interactiveShellInit = let
        navi-fish = pkgs.runCommandLocal "navi.fish" {} "${pkgs.navi}/bin/navi widget fish > $out";
      in ''
        # Keep fish when using nix-shell
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source

        # Cheatsheet
        # Use Ctrl + G to open
        source ${navi-fish}
      '';

      functions = {
        fish_user_key_bindings = ''
          # Ctrl-Backspace
          bind \e\[3^ kill-word

          # Ctrl-Delete
          bind \b backward-kill-word

          # Delete 'Ctrl-D to exit' binding, which causes accidental terminal exit
          # when ssh'd pagers hit EOF
          # https://stackoverflow.com/questions/34216850/how-to-prevent-iterm2-from-closing-when-typing-ctrl-d-eof
          # In bash, use:
          # https://unix.stackexchange.com/questions/139115/disable-ctrl-d-window-close-in-terminator-terminal-emulator
          bind --erase --preset \cd
        '';

        fish_greeting = "";

        fork = ''
          eval "$argv & disown > /dev/null"
        '';

        # TODO: pavil only
        fix-hdmi-audio = ''
          amixer -c 0 sset IEC958,1 unmute $argv
        '';
      };
    };

    tmux = {
      enable = true;
      sensibleOnTop = true;
      baseIndex = 1;
      clock24 = true;
      keyMode = "vi";
      prefix = "C-b";

      historyLimit = 50000;
      aggressiveResize = true;
      escapeTime = 0;
      terminal = "screen-256color";

      # Spawn a new session when attaching and none exist
      newSession = true;

      plugins = with pkgs.dlo9.tmuxPlugins; [
        {
          plugin = tmux-themepack;
          extraConfig = "set -g @themepack 'powerline/double/purple'";
        }
      ];

      extraConfig = ''
        # Gapless indexing
        set-option -g renumber-windows on

        # easy-to-remember split pane commands
        bind | split-window -h
        bind - split-window -v
        unbind '"'
        unbind %
      '';
    };

    starship = {
      enable = mkDefault true;
      enableFishIntegration = config.programs.fish.enable;

      # https://starship.rs/config
      settings = {
        line_break.disabled = true;
        time.disabled = false;
        cmd_duration.min_time = 1000;
        docker_context.disabled = true;
        gradle.disabled = true;
        java.disabled = true;
        gcloud.disabled = true;
        python.disabled = true;
        nodejs.disabled = true;
        golang.disabled = true;

        scan_timeout = 10;
        command_timeout = 100;

        status = {
          disabled = false;
          pipestatus = true;
        };

        # Don't need to know the current rust version
        rust.disabled = true;

        # Which package version this source builds
        package.disabled = true;
      };
    };

    ssh = {
      enable = mkDefault true;

      matchBlocks = {
        kvm-cuttlefish.user = "root";
        kvm-drywell.user = "root";
      };
    };
  };

  home.packages = with pkgs;
    mkIf config.programs.fish.enable [
      babelfish # bash to fish converter
    ];
}
