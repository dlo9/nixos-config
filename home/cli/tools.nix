{
  config,
  lib,
  pkgs,
  isLinux,
  isDarwin,
  mylib,
  ...
}:
with lib; {
  home = {
    sessionVariables = {
      PAGER = "bat --style='-header-filename'";
    };

    shellAliases = {
      # Use modern alternatives to classic unix tools
      # https://github.com/ibraheemdev/modern-unix
      du = "dust";
      df = "duf";
      cat = "bat";
      ls = "eza";
      grep = "rg";
      top = "btm";
      htop = "btm";
      ping = "gping";
      ps = "procs";
      watch = "viddy";
      z = "cd";

      carbonyl = "docker run --rm -it fathyb/carbonyl";
    };

    packages = with pkgs;
    # All systems
      [
        # Modern alternatives without aliases
        fd # Modern `find` alternative
        tealdeer # Simple `man` alternative
        mtr # Max traceroute

        # Modern alternatives with aliases
        dust
        duf
        bat
        eza
        ripgrep
        bottom
        gping
        procs
        viddy

        # Cheatsheet-like helpers
        navi
        fzf # Required for navi
        cheat

        # Terminal recorder
        #vhs # Requires chrome
        ttyd

        # Nix utils
        any-nix-shell # Doesn't change the interactive shell when using nix-shell
        alejandra # Formatter
        nix-diff
        nix-tree
        nh # Nix cli helper

        # Other utils
        curl
        go-task
        pv
        sops
        ouch # zip tool, since p7zip is annoying
        age
        unstable.nix-inspect
        tailspin # Log highlighter
        sd # Find and replace
        superfile # File explorer
        peco # Interactive filtering
        jnv # JSON interactive filtering
        clipboard-jh # `cb` a clipboard manager
        jc # CLI output to json
        eva # calculator

        # To try
        # dblab

        # Good tools, but don't need installed all the time
        # topgrade # Upgrade all the things
        # lemmeknow # Identify encoded strings
        # oha # HTTP benchmarker

        just
        nix-output-monitor
        dig
      ]
      ++
      # Linux only
      (optionals isLinux [
        lshw
        file

        # System utils
        lsof
        pciutils # lspci
        gptfdisk # Disk partitioning (sgdisk)
        kmon # Kernel monitor
        iputils # Required by gping

        bandwhich # Network monitor
        dua # Another disk space utility
        dive # Image layer explorer
      ]);
  };

  # https://github.com/atuinsh/atuin/issues/952#issuecomment-2163044297
  systemd.user = {
    sockets.atuin = {
      Unit.Description = "Atuin daemon";
      Socket.ListenStream = "%h/.local/share/atuin/atuin.sock"; # Default value for atuin
      Install.WantedBy = ["sockets.target"];
    };

    services.atuin = {
      Unit.Description = "Atuin daemon";
      Service.ExecStart = "${config.programs.atuin.package}/bin/atuin daemon";
    };
  };

  launchd.agents.atuin = {
    enable = true;
    config = {
      KeepAlive = true;
      ProcessType = "Interactive";
      ProgramArguments = ["${config.programs.atuin.package}/bin/atuin" "daemon"];
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/atuin/stderr";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/atuin/stdout";
    };
  };

  programs = {
    atuin = {
      enable = mkDefault true;
      enableFishIntegration = config.programs.fish.enable;

      settings = {
        # inline_height = 25; # https://github.com/atuinsh/atuin/issues/1289
        style = "compact";
        enter_accept = true;
        filter_mode = "session";

        # https://github.com/atuinsh/atuin/issues/952#issuecomment-2163044297
        daemon = {
          enabled = mkDefault true;
          sync_frequency = 60;
          socket_path =
            if isDarwin
            then "/tmp/atuin.${config.home.username}.socket"
            else "${config.home.homeDirectory}/.local/share/atuin/atuin.sock"; # Use a temporary location so that it's cleared on reboot
          systemd_socket = mkDefault isLinux;
        };
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
    };

    zoxide = {
      enable = mkDefault true;
      enableFishIntegration = config.programs.fish.enable;
      options = ["--cmd" "cd"];
    };

    bottom = {
      enable = mkDefault true;

      # https://github.com/ClementTsang/bottom/blob/master/sample_configs/default_config.toml
      settings = {
        flags = {
          mem_as_value = true;
        };

        # Ignore virtual interfaces
        network.interface_filter = {
          regex = true;
          list = [
            "lo"
            "veth.*"
            "ve-.*"
            "tailscale.*"
            "docker.*"
            "flannel.*"
            "mynet"
          ];
        };
      };
    };

    # I don't count this as a developer tool because it's needed for applying nix configs
    git = {
      enable = true;

      settings = {
        user = {
          name = "David Orchard";
          email = mkDefault "github@sigpanic.com";
        };

        init.defaultBranch = "main";
        pull.ff = "only";
        credential.helper = mkIf isLinux "${pkgs.gitFull}/bin/git-credential-libsecret";
        push.autoSetupRemote = true;
        #merge.conflictStyle = "zdiff3"; # Conflicts with mergiraf
        "url \"ssh://git@github.com/\"".insteadOf = "https://github.com/";

        # Sign git commits with SSH key
        gpg.format = "ssh";
        user.signingkey = "~/.ssh/id_ed25519.pub";
        commit.gpgsign = true;
      };

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
    };

    delta = {
      enable = true;
      enableGitIntegration = true;

      options = {
        line-numbers = true;
        hyperlinks = true;
        side-by-side = true;
        plus-style = "syntax #003500";
        plus-emph-style = "syntax #009900";
      };
    };
  };

  xdg.configFile = mylib.xdgFiles {
    "tealdeer/config.toml" = {
      updates.auto_update = true;
    };

    "viddy.toml" = {
      keymap = {
        timemachine_go_to_past = "Shift-Down";
        timemachine_go_to_future = "Shift-Up";
        timemachine_go_to_now = "Ctrl-Shift-Up";
        timemachine_go_to_oldest = "Ctrl-Shift-Down";
      };
    };
  };
}
