{
  inputs = {
    # Path types: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#types
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-previous.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Structure
    flake-parts.url = "github:hercules-ci/flake-parts";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
    terranix.url = "github:terranix/terranix";

    # Darwin settings
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
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
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    isd = {
      url = "github:isd-project/isd/v0.5.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Docker-compose in Nix
    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrap = {
      url = "github:dlo9/wrap/0.4.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      url = "github:NixOS/mobile-nixos";
      flake = false;
    };

    # Theming
    # A decent alternative (can generate color from picture): https://git.sr.ht/~misterio/nix-colors
    base16.url = "github:SenchoPens/base16.nix/v1.1.1";

    # Main theme
    # https://github.com/chriskempson/base16#scheme-repositories
    base16-atelier = {
      url = "github:atelierbram/base16-atelier-schemes";
      flake = false;
    };

    base16-unclaimed = {
      url = "github:chriskempson/base16-unclaimed-schemes";
      flake = false;
    };

    # Theme templates
    # https://github.com/chriskempson/base16#template-repositories
    base16-shell = {
      url = "github:chriskempson/base16-shell";
      flake = false;
    };

    base16-fish-shell = {
      url = "github:FabioAntunes/base16-fish-shell";
      flake = false;
    };

    base16-alacritty = {
      url = "github:aarowill/base16-alacritty";
      flake = false;
    };

    base16-mako = {
      url = "github:Eluminae/base16-mako";
      flake = false;
    };

    base16-wofi = {
      url = "https://git.sr.ht/~knezi/base16-wofi/archive/v1.0.tar.gz";
      flake = false;
    };

    base16-waybar = {
      url = "github:mnussbaum/base16-waybar";
      flake = false;
    };

    base16-gtk = {
      url = "github:tinted-theming/base16-gtk-flatcolor";
      flake = false;
    };
  };

  outputs = inputs @ {flake-parts, ...}:
  # https://flake.parts/module-arguments.html
    flake-parts.lib.mkFlake {inherit inputs;} (top @ {
      self,
      config,
      withSystem,
      moduleWithSystem,
      ...
    }: {
      imports = [
        # flake-parts plugins
        inputs.pkgs-by-name-for-flake-parts.flakeModule
        inputs.terranix.flakeModule
      ];

      flake = let
        systemOverlay = system: final: prev: {
          dlo9 = inputs.nixpkgs.lib.filesystem.packagesFromDirectoryRecursive {
            inherit (final) callPackage;
            directory = ./pkgs;
          };

          unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfree = prev.config.allowUnfree;
          };

          master = import inputs.nixpkgs-master {
            inherit system;
            config.allowUnfree = prev.config.allowUnfree;
          };

          previous = import inputs.nixpkgs-previous {
            inherit system;
            config.allowUnfree = prev.config.allowUnfree;
          };

          isd = inputs.isd.packages.${system}.isd;
        };

        androidModules = [
          # System modules
          ./system/home-manager.nix
          ./system/options.nix
          # ./system/secrets.nix

          # Host modules
          ./hosts

          # Nix User repo
          #inputs.nur.modules.nixos.default

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

              overlays = [
                (systemOverlay config.nixpkgs.hostPlatform.system)
                inputs.wrap.overlays.default
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

              overlays = [
                inputs.nix-darwin.overlays.default
                (systemOverlay config.nixpkgs.hostPlatform.system)

                # Nix User repo
                inputs.nur.overlays.default
                inputs.wrap.overlays.default
              ];
            };
          })
        ];

        specialArgs = ctx: os: hostname: {
          inherit inputs hostname;
          isDarwin = os == "darwin";
          isLinux = os == "linux";
          isAndroid = os == "android";
          mylib = ctx.pkgs.callPackage ./lib {inherit inputs;};
        };

        # Use nixpkgs cache for deploy-rs: https://github.com/serokell/deploy-rs?tab=readme-ov-file#api
        deployPkgs = system:
          import inputs.nixpkgs {
            inherit system;

            overlays = [
              inputs.deploy-rs.overlays.default

              (self: super: {
                deploy-rs = {
                  inherit (import inputs.nixpkgs {inherit system;}) deploy-rs;
                  lib = super.deploy-rs.lib;
                };
              })
            ];
          };

        activateNixOnDroid = configuration:
          (deployPkgs "aarch64-linux").deploy-rs.lib.activate.custom
            configuration.activationPackage
            "${configuration.activationPackage}/activate";
      in {
        # Test with: nix eval 'path:.#nixOnDroidConfigurations.pixie.config'
        nixOnDroidConfigurations.pixie = withSystem "aarch64-linux" (
          ctx @ {
            config,
            inputs',
            system,
            ...
          }:
            inputs.nix-on-droid.lib.nixOnDroidConfiguration {
              extraSpecialArgs = specialArgs ctx "android" "pixie";
              home-manager-path = inputs.home-manager.outPath;
              modules = androidModules;

              pkgs = import inputs.nixpkgs {
                inherit system;

                config.allowUnfree = true;

                overlays = [
                  inputs.nix-on-droid.overlays.default
                  (systemOverlay system)
                  inputs.wrap.overlays.default
                ];
              };
            }
        );

        # nix run nixpkgs#deploy-rs -- --skip-checks --auto-rollback false -k .#pixie -- --impure
        # https://github.com/nix-community/nix-on-droid/wiki/Remote-deploy-with-deploy%E2%80%90rs
        deploy.nodes.pixie = {
          hostname = "pixie";
          sshUser = "nix-on-droid";
          user = "nix-on-droid";
          #interactiveSudo = true;
          fastConnection = true;
          sshOpts = [ "-p" "8022" ];

          #profiles.system.path = (deployPkgs "aarch64-linux").deploy-rs.lib.activate.nixos self.nixosConfigurations.trident;
          #profiles.nix-on-droid.path = (deployPkgs "aarch64-linux").deploy-rs.lib.aarch64-linux.activate.custom self.nixOnDroidConfigurations.pixie.activationPackage "${self.nixOnDroidConfigurations.pixie.activationPackage}/activate";
          #profiles.nix-on-droid.path = (deployPkgs "aarch64-linux").deploy-rs.lib.activate.custom self.nixOnDroidConfigurations.pixie.activationPackage "${self.nixOnDroidConfigurations.pixie.activationPackage}/activate";
          profiles.system.path = activateNixOnDroid self.nixOnDroidConfigurations.pixie;
          #profiles.system.path = (deployPkgs "aarch64-linux").deploy-rs.lib.activate.nixos self.nixosConfigurations.trident;
        };

        darwinConfigurations.YX6MTFK902 = withSystem "aarch64-darwin" (
          ctx @ {
            config,
            inputs',
            system,
            ...
          }:
            inputs.nix-darwin.lib.darwinSystem {
              specialArgs = specialArgs ctx "darwin" "mallow";
              inherit system;
              modules = darwinModules;
            }
        );

        nixosConfigurations.cuttlefish = withSystem "x86_64-linux" (
          ctx @ {
            config,
            inputs',
            system,
            ...
          }:
            inputs.nixpkgs.lib.nixosSystem {
              specialArgs = specialArgs ctx "linux" "cuttlefish";
              inherit system;
              modules = linuxModules;
            }
        );

        nixosConfigurations.drywell = withSystem "x86_64-linux" (
          ctx @ {
            config,
            inputs',
            system,
            ...
          }:
            inputs.nixpkgs.lib.nixosSystem {
              specialArgs = specialArgs ctx "linux" "drywell";
              inherit system;
              modules = linuxModules;
            }
        );

        # nix run nixpkgs#deploy-rs -- --skip-checks -k .#drywell
        deploy.nodes.drywell = {
          hostname = "drywell";
          sshUser = "david";
          user = "root";
          interactiveSudo = true;
          fastConnection = true;

          profiles.system.path = (deployPkgs "x86_64-linux").deploy-rs.lib.activate.nixos self.nixosConfigurations.drywell;
        };

        nixosConfigurations.wyse = withSystem "x86_64-linux" (
          ctx @ {
            config,
            inputs',
            system,
            ...
          }:
            inputs.nixpkgs.lib.nixosSystem {
              specialArgs = specialArgs ctx "linux" "wyse";
              inherit system;
              modules = linuxModules;
            }
        );

        # nix run nixpkgs#deploy-rs -- --skip-checks -k .#wyse
        deploy.nodes.wyse = {
          hostname = "wyse";
          sshUser = "david";
          user = "root";
          interactiveSudo = true;
          fastConnection = true;

          profiles.system.path = (deployPkgs "x86_64-linux").deploy-rs.lib.activate.nixos self.nixosConfigurations.wyse;
        };

        nixosConfigurations.pavil = withSystem "x86_64-linux" (
          ctx @ {
            config,
            inputs',
            system,
            ...
          }:
            inputs.nixpkgs.lib.nixosSystem {
              specialArgs = specialArgs ctx "linux" "pavil";
              inherit system;
              modules = linuxModules;
            }
        );

        nixosConfigurations.trident = withSystem "aarch64-linux" (
          ctx @ {
            config,
            inputs',
            system,
            ...
          }:
            inputs.nixpkgs.lib.nixosSystem {
              specialArgs = specialArgs ctx "linux" "trident";
              inherit system;
              modules =
                linuxModules
                ++ [
                  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
                  {
                    nixpkgs.overlays = [
                      (final: super: {
                        makeModulesClosure = x:
                          super.makeModulesClosure (x // {allowMissing = true;});
                      })
                    ];
                  }
                ];
            }
        );

        nixosConfigurations.trident-sd-card = withSystem "aarch64-linux" (
          ctx @ {
            config,
            inputs',
            system,
            ...
          }:
            inputs.nixpkgs.lib.nixosSystem {
              specialArgs = specialArgs ctx "linux" "trident";
              inherit system;
              modules =
                linuxModules
                ++ [
                  {
                    imports = ["${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"];

                    sdImage = {
                      populateRootCommands = ''
                        mkdir files/etc
                        cp -r ${inputs.self} files/etc/nixos

                        mkdir files/var
                        chmod 755 files/var

                        cp "/impure/sops-age-keys.txt" "files/var/sops-age-keys.txt"
                        chmod 600 "files/var/sops-age-keys.txt"
                      '';
                    };
                  }

                  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
                  {
                    nixpkgs.overlays = [
                      (final: super: {
                        makeModulesClosure = x:
                          super.makeModulesClosure (x // {allowMissing = true;});
                      })
                    ];
                  }
                ];
            }
        );

        # nix run nixpkgs#deploy-rs -- --skip-checks --auto-rollback false -k .#trident
        deploy.nodes.trident = {
          hostname = "trident";
          sshUser = "pi";
          user = "root";
          interactiveSudo = true;
          fastConnection = true;

          profiles.system.path = (deployPkgs "aarch64-linux").deploy-rs.lib.activate.nixos self.nixosConfigurations.trident;
        };

        # This is highly advised, and will prevent many possible mistakes
        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
      };

      systems = [
        # systems for which you want to build the `perSystem` attributes
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {
        config,
        pkgs,
        self',
        ...
      }: {
        # https://github.com/drupol/pkgs-by-name-for-flake-parts
        # pkgsDirectory = ./pkgs;

        formatter = pkgs.alejandra;

        packages = let
          change-to-flake-root = ''
            # Change to flake root
            while [ ! -f "flake.nix" ] && [ "$PWD" != "/" ]; do
              cd ..
            done
          '';

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
        in {
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

              ${self'.packages.generate-hardware}/bin/generate-hardware

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
                sudo -v # Nom has an issue with hiding the sudo message
                sudo darwin-rebuild --flake ".#$HOSTNAME" "$@" --option fallback true --option http2 false --show-trace |& nom
              elif [[ "$OS" == "android" ]]; then
                nix-on-droid --flake ".#$HOSTNAME" "$@" --option fallback true --show-trace |& nom
              else
                echo "Unknown os: $OS"
                exit 1
              fi
            '';
          };
        };

        apps = {
          # nix run ".#default" build
          # nix run ".#default" switch
          default = {
            type = "app";
            program = "${self'.packages.build}/bin/build";
          };

          # nix run ".#generate-hardware"
          generate-hardware = {
            type = "app";
            program = "${self'.packages.generate-hardware}/bin/generate-hardware";
          };
        };
      };
    });
}
