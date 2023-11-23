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
        rnix-lsp # Nix language server

        # Other utils
        curl
        go-task
        pv
        sops
        p7zip
        zstd
        age

        # TODO: remove when upgrading to 23.11 in favor of programs.yazi
        pkgs.unstable.yazi
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
      ]);
  };

  programs = {
    zoxide = {
      enable = mkDefault true;
      enableFishIntegration = config.programs.fish.enable;
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
      };
    };

    # TODO: enable when upgrading to 23.11
    # yazi = {
    #   enable = true;
    #   # TODO: theme, settings, keymap
    # };
  };
}
