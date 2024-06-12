{
  config,
  lib,
  pkgs,
  isLinux,
  ...
}:
with lib; {
  home = {
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

      carbonyl = "docker run --rm -it fathyb/carbonyl";
    };

    packages = with pkgs;
    # All systems
      [
        # Modern alternatives without aliases
        fd # Modern `find` alternative
        tldr # Simple `man` alternative
        mtr # Max traceroute

        # Modern alternatives with aliases
        du-dust
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
        vhs
        ttyd

        # Nix utils
        any-nix-shell # Doesn't change the interactive shell when using nix-shell
        nix-prefetch
        alejandra # Formatter
        nix-diff
        nix-tree
        nixd # Nix language server

        # Other utils
        curl
        go-task
        pv
        sops
        p7zip
        zstd
        age
        glow # Markdown reader
        trippy # Network diagnostics
        unstable.nix-inspect
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
        inxi # Hardware info
        kmon # Kernel monitor
        flashrom
        iputils # Required by gping

        immich-cli # Bulk image uploading
        nvtopPackages.intel # GPU monitoring
        noseyparker # Credential scanner
      ]);
  };

  # https://github.com/atuinsh/atuin/issues/952#issuecomment-2163044297
  systemd.user.services.atuin = {
    Unit.Description = "Atuin daemon";
    Service.ExecStart = "${config.programs.atuin.package}/bin/atuin daemon";
    Install.WantedBy = ["default.target"];
  };

  programs = {
    atuin = {
      enable = mkDefault true;
      enableFishIntegration = config.programs.fish.enable;

      # Remove once stable is up to 18.3.0
      # https://github.com/atuinsh/atuin/issues/952#issuecomment-2163044297
      package = pkgs.master.atuin;

      settings = {
        # inline_height = 25; # https://github.com/atuinsh/atuin/issues/1289
        style = "compact";
        enter_accept = true;
        filter_mode = "session";

        # https://github.com/atuinsh/atuin/issues/952#issuecomment-2163044297
        daemon.enabled = true;
      };
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
      };
    };

    # I don't count this as a developer tool because it's needed for applying nix configs
    git = {
      enable = true;
      userName = "David Orchard";
      userEmail = "if_coding@fastmail.com";

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
        credential.helper = mkIf isLinux "${pkgs.gitAndTools.gitFull}/bin/git-credential-libsecret";
        push.autoSetupRemote = true;
        merge.conflictStyle = "zdiff3";
      };
    };

    yazi = {
      enable = true;

      settings = {
        manager = {
          sort_by = "natural";
          sort_sensitive = false;
          sort_reverse = false;
          sort_dir_first = true;
          linemode = "size";
          show_hidden = true;
          show_symlink = true;
        };
      };
    };
  };
}
