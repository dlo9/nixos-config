{
  inputs = {
    # Path types: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#types
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    nixpkgs-master.url = github:NixOS/nixpkgs/master;
    nixpkgs.url = github:NixOS/nixpkgs/nixos-24.11;
    nixpkgs-darwin.url = github:NixOS/nixpkgs/nixpkgs-24.11-darwin;

    # Darwin settings
    nix-darwin = {
      url = github:LnL7/nix-darwin;
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Library functions
    flake-utils.url = "github:numtide/flake-utils";
    nix-std.url = "github:chessai/nix-std";

    # Available modules: https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    check_mk_agent = {
      url = "github:BenediktSeidl/nixos-check_mk_agent-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management
    sops-nix = {
      url = github:Mic92/sops-nix;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      url = github:nix-community/home-manager/release-24.11;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Docker-compose in Nix
    arion = {
      url = github:hercules-ci/arion;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = github:nix-community/NUR;

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mobile-nixos = {
      url = github:NixOS/mobile-nixos;
      flake = false;
    };

    # Theming
    # A decent alternative (can generate color from picture): https://git.sr.ht/~misterio/nix-colors
    base16.url = github:SenchoPens/base16.nix/v1.1.1;

    # Main theme
    # https://github.com/chriskempson/base16#scheme-repositories
    base16-atelier = {
      url = github:atelierbram/base16-atelier-schemes;
      flake = false;
    };

    base16-unclaimed = {
      url = github:chriskempson/base16-unclaimed-schemes;
      flake = false;
    };

    # Theme templates
    # https://github.com/chriskempson/base16#template-repositories
    base16-shell = {
      url = github:chriskempson/base16-shell;
      flake = false;
    };

    base16-fish-shell = {
      url = github:FabioAntunes/base16-fish-shell;
      flake = false;
    };

    base16-alacritty = {
      url = github:aarowill/base16-alacritty;
      flake = false;
    };

    base16-mako = {
      url = github:Eluminae/base16-mako;
      flake = false;
    };

    base16-wofi = {
      url = https://git.sr.ht/~knezi/base16-wofi/archive/v1.0.tar.gz;
      flake = false;
    };

    base16-waybar = {
      url = github:mnussbaum/base16-waybar;
      flake = false;
    };

    base16-sway = {
      url = github:rkubosz/base16-sway;
      flake = false;
    };

    base16-gtk = {
      url = github:tinted-theming/base16-gtk-flatcolor;
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    overlays = {
      dlo9 = import ./pkgs inputs;

      unstable = system: final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = prev.config.allowUnfree;
        };
      };

      master = system: final: prev: {
        master = import inputs.nixpkgs-master {
          inherit system;
          config.allowUnfree = prev.config.allowUnfree;
        };
      };
    };

    linuxModules = [
      # System modules
      ./system

      # Host modules
      ./hosts

      # Nix User repo
      inputs.nur.modules.nixos.default

      # Docker-compose in Nix
      inputs.arion.nixosModules.arion

      # Nixpkgs overlays
      ({
        config,
        inputs,
        ...
      }: {
        nixpkgs = {
          config.allowUnfree = true;

          overlays = with overlays; [
            dlo9
            (unstable "x86_64-linux")
            (master "x86_64-linux")
          ];
        };
      })
    ];

    darwinModules = [
      # System modules
      ./system

      # Host modules
      ./hosts

      # Nixpkgs overlays
      ({
        config,
        inputs,
        ...
      }: {
        nixpkgs = {
          hostPlatform = "aarch64-darwin";
          config.allowUnfree = true;

          overlays = with overlays; [
            inputs.nix-darwin.overlays.default
            dlo9
            (unstable "aarch64-darwin")
            (master "aarch64-darwin")

            # Nix User repo
            inputs.nur.overlays.default
          ];
        };
      })
    ];

    androidModules = [
      # System modules
      ./system/home-manager.nix
      ./system/options.nix
      # ./system/secrets.nix

      # Host modules
      ./hosts

      # Nix User repo
      inputs.nur.modules.nixos.default

      ({config, ...}: {
        environment.motd = null;

        home-manager = {
          useUserPackages = false; # TODO
          extraSpecialArgs = {
            osConfig = config;
          };
        };
      })
    ];

    # Pass extra arguments to modules
    specialArgs = {
      inherit inputs;
      isDarwin = false;
      isLinux = true;
      isAndroid = false;
    };
  in rec {
    # https://daiderd.com/nix-darwin/manual/index.html
    darwinConfigurations = with inputs.nix-darwin.lib; rec {
      mallow = darwinSystem {
        specialArgs = {
          inherit inputs;
          isDarwin = true;
          isLinux = false;
          isAndroid = false;
          hostname = "mallow";
        };

        system = "aarch64-darwin";
        modules = darwinModules;
      };

      YX6MTFK902 = mallow;
    };

    nixOnDroidConfigurations = with inputs.nix-on-droid.lib; rec {
      pixie = nixOnDroidConfiguration {
        extraSpecialArgs = {
          inherit inputs;
          isDarwin = false;
          isLinux = false;
          isAndroid = true;
          hostname = "pixie";
        };

        home-manager-path = inputs.home-manager.outPath;

        system = "aarch64-linux";
        modules = androidModules;

        pkgs = import nixpkgs {
          system = "aarch64-linux";

          config.allowUnfree = true;

          overlays = with overlays; [
            inputs.nix-on-droid.overlays.default
            dlo9
            (unstable "aarch64-linux")
            (master "aarch64-linux")
          ];
        };
      };
    };

    nixosConfigurations = with nixpkgs.lib; rec {
      bee = nixosSystem {
        specialArgs = specialArgs // {hostname = "bee";};

        system = "x86_64-linux";
        modules = linuxModules;
      };

      cuttlefish = nixosSystem {
        specialArgs = specialArgs // {hostname = "cuttlefish";};

        system = "x86_64-linux";
        modules = linuxModules;
      };

      nib = nixosSystem {
        specialArgs = specialArgs // {hostname = "nib";};
        system = "x86_64-linux";
        modules = linuxModules;
      };

      pavil = nixosSystem {
        specialArgs = specialArgs // {hostname = "pavil";};
        system = "x86_64-linux";
        modules = linuxModules;
      };

      # https://mobile.nixos.org/devices/motorola-potter.html
      # - Test with: nix eval "/etc/nixos#nixosConfigurations.moto.config.system.build.toplevel.drvPath"
      # - Build with: nixos-rebuild build --flake path:///etc/nixos#moto
      moto = nixosSystem {
        specialArgs = specialArgs // {hostname = "moto";};

        system = "aarch64-linux";
        modules =
          linuxModules
          ++ [
            (import "${inputs.mobile-nixos}/lib/configuration.nix" {device = "motorola-potter";})
          ];
      };

      # Build with: `nix build 'path:.#nixosConfigurations.moto-image'`
      # Impure needed to access host paths without putting in the nix store
      moto-image = moto.config.mobile.outputs.android.android-fastboot-images;

      rpi3 = nixosSystem {
        specialArgs = specialArgs // {hostname = "rpi3";};

        system = "aarch64-linux";
        modules =
          linuxModules
          ++ [
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ];
      };

      # Build with: `nix build --impure 'path:.#nixosConfigurations.rpi3-image'`
      # Impure needed to access host paths without putting in the nix store
      rpi3-image = rpi3.config.system.build.sdImage;

      drywell = nixosSystem {
        specialArgs = specialArgs // {hostname = "drywell";};

        system = "x86_64-linux";
        modules = linuxModules;
      };

      installer-test = nixosSystem {
        specialArgs = specialArgs // {hostname = "installer-test";};

        system = "x86_64-linux";
        modules = linuxModules;
      };
    };

    # packages.x86_64-linux = {
    #   vmware = inputs.nixos-generators.nixosGenerate {
    #     system = "x86_64-linux";
    #     modules = [ ];
    #     format = "iso";
    #   };
    # };

    inherit overlays;

    packages = let
      change-to-flake-root = ''
        # Change to flake root
        while [ ! -f "flake.nix" ] && [ "$PWD" != "/" ]; do
          cd ..
        done
      '';
    in
      inputs.flake-utils.lib.eachDefaultSystemMap (
        system: let
          pkgs = nixpkgs.legacyPackages.${system};

          setVars = ''
            if command -v nixos-rebuild >/dev/null; then
              OS=linux
            elif command -v darwin-rebuild >/dev/null; then
              OS=darwin
            elif command -v nix-on-droid >/dev/null; then
              OS=android
            fi

            if [ -z "$HOSTNAME" ]; then
              HOSTNAME="$(hostname)"
            fi
          '';
        in rec {
          default = {
            type = "app";
            program = "${packages.${system}.build}/bin/build";
          };

          generate-hardware = pkgs.writeShellApplication {
            name = "generate-hardware";

            # TODO: not yet supported
            # runtimeEnv = {
            #   SYSTEM = system;
            # };

            text = ''
              ${setVars}

              ${change-to-flake-root}

              if [[ "$OS" == "linux" ]]; then
                echo "Generating hardware config"

                config="hosts/$HOSTNAME/hardware/generated.nix"
                mkdir -p "$(dirname "$config")"

                # Ask for sudo now, so that the file isn't truncated
                # if sudo fails
                sudo -v

                # Must use `sudo` so that all mounts are visible
                sudo nixos-generate-config --show-hardware-config | \
                  scripts/maintenance/process-hardware-config.awk > "$config"

                echo "Formatting hardware config"
                nix fmt -- -q "$config"
              fi
            '';
          };

          build = pkgs.writeShellApplication {
            name = "build";

            # TODO: not yet supported
            # runtimeEnv = {
            #   SYSTEM = system;
            # };

            text = ''
              ${setVars}

              # If no options were provided, then default to switch
              if [[ "''${#@}" == 0 ]]; then
                set -- switch
              fi

              ${change-to-flake-root}

              # Format
              echo "Formatting config"
              nix fmt -- -q .

              ${generate-hardware}/bin/generate-hardware

              # Install nom for better build output
              echo "Installing nom..."
              nix build nixpkgs#nix-output-monitor
              PATH="$PATH:$(nix path-info nixpkgs#nix-output-monitor)/bin"

              if [[ "$OS" == "linux" ]]; then
                sudo nixos-rebuild "$@" --option fallback true --show-trace |& nom
              elif [[ "$OS" == "darwin" ]]; then
                # Copy cert file already on the machine
                certSource="/etc/ssl/afscerts/ca-certificates.crt"
                if [ -f "$certSource" ]; then
                  cp "$certSource" "hosts/mallow/ca-certificates.crt"
                fi

                # Rebuild
                darwin-rebuild --flake ".#$HOSTNAME" "$@" --option fallback true --show-trace |& nom
              elif [[ "$OS" == "android" ]]; then
                nix-on-droid --flake ".#$HOSTNAME" "$@" --option fallback true --show-trace |& nom
              else
                echo "Unknown os: $OS"
                exit 1
              fi
            '';
          };
        }
      );

    apps = inputs.flake-utils.lib.eachDefaultSystemMap (
      system: {
        # nix run ".#default" build
        # nix run ".#default" switch
        default = {
          type = "app";
          program = "${packages.${system}.build}/bin/build";
        };

        # nix run ".#generate-hardware"
        generate-hardware = {
          type = "app";
          program = "${packages.${system}.generate-hardware}/bin/generate-hardware";
        };
      }
    );

    formatter = inputs.flake-utils.lib.eachDefaultSystemMap (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
