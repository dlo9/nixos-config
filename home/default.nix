# Home manager configuration
# - Manual: https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
# - Config: https://rycee.gitlab.io/home-manager/options.html
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; {
  imports = [
    inputs.base16.homeManagerModule
    ./graphical
    ./options.nix
    ./vim.nix
  ];

  scheme = "${inputs.base16-atelier}/atelier-seaside.yaml";
  #scheme = "${inputs.base16-unclaimed}/apathy.yaml";

  home = {
    stateVersion = "22.05";
    sessionPath = [
      "$HOME/.cargo/bin"
      "$HOME/.local/bin"
    ];

    sessionVariables = {
      EDITOR = "vim";
      SOPS_AGE_KEY_FILE = "/var/sops-age-keys.txt";
    };

    shellAliases = {
      # k = "kubectl";

      # Use modern alternatives to classic unix tools
      # https://github.com/ibraheemdev/modern-unix
      du = "${pkgs.du-dust}/bin/dust";
      df = "${pkgs.duf}/bin/duf";
      cat = "${pkgs.bat}/bin/bat";
      ls = "${pkgs.exa}/bin/exa";
      grep = "${pkgs.ripgrep}/bin/rg";
      top = "${pkgs.bottom}/bin/btm";
      htop = "${pkgs.bottom}/bin/btm";
      ping = "${pkgs.gping}/bin/gping";
      ps = "${pkgs.procs}/bin/procs";
      watch = "${pkgs.viddy}/bin/viddy";

      carbonyl = "docker run --rm -it fathyb/carbonyl";
    };
  };

  # Allow user-installed fonts
  fonts.fontconfig.enable = true;

  programs = {
    git = {
      enable = true;
      userName = "David Orchard";
      userEmail = "if_coding@fastmail.com";

      difftastic.enable = false;
      lfs.enable = true;

      ignores = [
        # Temporary files
        "*~"
        "*.swp"
        "*.swo"

        # Backups
        "*.old"

        # Logs
        "*.log"
      ];

      extraConfig = {
        init.defaultBranch = "main";
        pull.ff = "only";
        credential.helper = "${pkgs.gitAndTools.gitFull}/bin/git-credential-libsecret";
        push.autoSetupRemote = true;
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

      plugins = with pkgs.tmuxPlugins; [
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

    fish = {
      enable = true;

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
        # Theme
        # Babelfish can't handle the official shell theme
        for f in ${inputs.base16-fish-shell}/functions/__*.fish
          source $f
        end

        source ${config.scheme inputs.base16-fish-shell}
        base16-${config.scheme.scheme-slug}

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

    starship = {
      enable = true;
      enableFishIntegration = true;

      # https://starship.rs/config
      settings = {
        line_break.disabled = true;
        time.disabled = false;
        cmd_duration.min_time = 1000;

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

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    bottom = {
      enable = true;

      # https://github.com/ClementTsang/bottom/blob/master/sample_configs/default_config.toml
      settings = {
        flags = {
          mem_as_value = true;
        };
      };
    };
  };

  xdg = {
    enable = true;
    configFile = {
      "nixpkgs/config.nix".text = ''
        {
          allowUnfree = true;
        }
      '';

      "wrap.yaml".source = mkDefault ./wrap.yaml;
    };
  };

  home.packages = with pkgs; [
    # Terminal
    nodejs # For vim plugins

    # bash to fish converter
    babelfish

    # Modern alternatives without aliases
    fd # Modern `find` alternative
    tldr # Simple `man` alternative
    mtr

    # Modern alternatives with aliases
    du-dust
    duf
    bat
    exa
    ripgrep
    bottom
    gping
    procs
    viddy

    # Some dev tools
    yq-go
    jq
    shellcheck

    # Cheatsheet-like helpers
    navi
    fzf # Required for navi
    cheat

    # Terminal recorder
    vhs
    ttyd

    # Nix utils
    any-nix-shell # Doesn't change the interactive shell when using nix-shell
    nix-prefetch
    alejandra # Formatter

    # Other utils
    go-task
    pv
    sops
    p7zip
    zstd
    age
  ];
}
