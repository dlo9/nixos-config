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

      interactiveShellInit = ''
        # Keep fish when using nix-shell
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
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
      terminal = "tmux-256color";

      # Spawn a new session when attaching and none exist
      newSession = true;

      extraConfig = ''
        # Gapless indexing
        set-option -g renumber-windows on

        # easy-to-remember split pane commands
        bind | split-window -h
        bind - split-window -v
        unbind '"'
        unbind %

        # Pass extended key sequences (e.g. Shift+Enter) through to applications
        # https://github.com/anthropics/claude-code/issues/6072#issuecomment-3878383365
        set -g extended-keys on
        bind-key -T root S-Enter send-keys Escape "[13;2u"

        # Pane borders
        set -g pane-border-lines heavy
        set -g pane-border-indicators arrows
        set -g pane-border-status top
        # set -g pane-border-format ""

        # Theme
        set -as terminal-features ",*:RGB"
        set -g allow-passthrough on
        source-file ~/.local/share/tinted-theming/tinty/tmux-colors-file.conf
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
        aws.disabled = true;
        nix_shell.format = "$symbol ";
        nix_shell.symbol = "";

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

        # When using jj, we're usually in a detached head state
        git_branch.only_attached = true;
        git_commit.disabled = true;
        git_status.disabled = true;
      };
    };

    ssh = {
      enable = mkDefault true;
      enableDefaultConfig = false;

      matchBlocks = {
        kvm-cuttlefish.user = "root";
        kvm-drywell.user = "root";
        cuttlefish.user = "david";
        opnsense.user = "root";
        trident.user = "pi";

        pixie = {
          identitiesOnly = true;
          user = "nix-on-droid";
          hostname = "google-pixel-6";
          port = 8022;
        };

        # From default config
        "*" = {
          forwardAgent = false;
          addKeysToAgent = "no";
          compression = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };
      };
    };
  };

  home.packages = with pkgs;
    mkIf config.programs.fish.enable [
      babelfish # bash to fish converter
    ];
}
