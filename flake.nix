{
  inputs = {
    # Path types: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#types
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    nixpkgs.url = github:NixOS/nixpkgs/nixos-23.05;

    # Old release for EOL kernel 6.2. 6.1 doesn't support Intel ARC, and 6.3 doesn't support ZFS.
    # 6.2 was removed in https://github.com/NixOS/nixpkgs/commit/10d5a682701d1bfd16e62459026d0df54cc3d314
    # TODO: Remove once 6.3 supports ZFS
    nixpkgs-kernel.url = github:NixOS/nixpkgs/nixpkgs-unstable;

    # Darwin settings
    nixpkgs-darwin.url = github:NixOS/nixpkgs/nixpkgs-23.05-darwin;
    nix-darwin = {
      url = github:LnL7/nix-darwin/release-23.05;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

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
      # TODO: change back when babelfish commit is in the stable release:
      # https://github.com/nix-community/home-manager/commit/53ccbe017079d5fba2b605cb9f9584629bebd03a
      #url = github:nix-community/home-manager/release-23.05;
      url = github:nix-community/home-manager/53ccbe017079d5fba2b605cb9f9584629bebd03a;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager-darwin = {
      # TODO: change back when babelfish commit is in the stable release:
      # https://github.com/nix-community/home-manager/commit/53ccbe017079d5fba2b605cb9f9584629bebd03a
      #url = github:nix-community/home-manager/release-23.05;
      url = github:nix-community/home-manager/53ccbe017079d5fba2b605cb9f9584629bebd03a;
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Docker-compose in Nix
    arion = {
      url = github:hercules-ci/arion;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = github:nix-community/NUR;

    vscode-server = {
      url = "github:msteen/nixos-vscode-server";
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
  } @ inputs:
    with nixpkgs.lib;
    with builtins; let
      optionalModule = optionalFile: args: (optionalAttrs (pathExists optionalFile) (import optionalFile args));

      # Returns an array of the hostnames under `./hosts/`
      hosts = attrNames (filterAttrs (n: v: v == "directory") (readDir ./hosts));

      hostFile = hostName: fileName: ./hosts/${hostName}/${fileName};
      hostFileExists = hostName: fileName: pathExists (hostFile hostName fileName);

      # Recursively merge an attribute set. If all elements at a path are:
      #   attrs: recursively apply
      #   lists: flatten into a unique list
      #   mixed: merge into a unique list
      recursiveAttrsToList = let
        f = zipAttrsWith (
          name: values:
            if all isAttrs values
            then f values
            else if all isList values
            then unique (concatLists values)
            else unique values
        );
      in
        f;

      # A combined AttrSet of all host exports
      # TODO: pretty redundant
      hostExport = hostName: optionalAttrs (hostFileExists hostName "exports.nix") (import (hostFile hostName "exports.nix"));
      hostExportAttr = hostName: nameValuePair hostName (hostExport hostName);
      exports = listToAttrs (forEach hosts hostExportAttr);
      mergedExports = recursiveAttrsToList (forEach hosts hostExport);

      hostModules = hostName: [
        # Host-specific config
        ./hosts/${hostName}

        {networking.hostName = hostName;}
      ];

      overlays = {
        # default = final: prev:
        #   prev.lib.recursiveUpdate prev (prev.pkgs.callPackage ./pkgs {});
        # default = final: prev: import ./pkgs { lib = prev.pkgs.lib; callPackage = prev.pkgs.callPackage; };
        # default = final: prev: prev.lib.recursiveUpdate prev (import ./pkgs { lib = prev.pkgs.lib; callPackage = prev.pkgs.callPackage; });
        default = final: prev:
          with prev; let
            pkgs' = recurseIntoAttrs (callPackage ./pkgs {});
          in
            # prev.lib.recursiveUpdate pkgs pkgs';
            # prev.lib.mapAttrs ;
            {
              vimPlugins = prev.vimPlugins // pkgs'.vimPlugins;
              tmuxPlugins = prev.tmuxPlugins // pkgs'.tmuxPlugins;
              # lib = prev.lib // pkgs'.lib;

              flatcolor-gtk-theme = pkgs'.flatcolor-gtk-theme;
              lxappearance-xwayland = pkgs'.lxappearance-xwayland;
              nss-docker = pkgs'.nss-docker;
              caddy = pkgs'.caddy;
              fromYAML = pkgs'.fromYAML;
            };

        # (recurseIntoAttrs (callPackage ./pkgs { }));
        # prev.lib.recursiveUpdate prev (prev.lib.recurseIntoAttrs (prev.callPackage ./pkgs { }));
        # prev.lib.recursiveUpdate prev (prev.lib.recurseIntoAttrs (prev.callPackage ./pkgs { }));

        # pkgs = prev.lib.recursiveUpdate prev.pkgs (prev.pkgs.callPackage ./pkgs { });
        # recurseIntoAttrs (callPackage ./vim-plugins { })

        unstable = system: final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfree = prev.config.allowUnfree;
          };
        };

        kernel = system: final: prev: {
          kernel = import inputs.nixpkgs-kernel {
            inherit system;
            config.allowUnfree = prev.config.allowUnfree;
          };
        };
      };

      defaultModules = hostName: extraSettings:
        [
          # Custom system modules
          ./sys

          # Nix User repo
          inputs.nur.nixosModules.nur

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
                default
                (unstable "x86_64-linux")
                (kernel "x86_64-linux")
              ];
            };
          })

          # Home-manager configuration
          ./home/nixos-module.nix

          # Passed-in module
          extraSettings
        ]
        ++ (hostModules hostName);

      # Pass extra arguments to modules
      specialArgs.inputs =
        inputs
        // {
          inherit exports hostFile mergedExports;
        };
    in rec {
      # https://daiderd.com/nix-darwin/manual/index.html
      darwinConfigurations = with inputs.nix-darwin.lib; {
        mallow = darwinSystem {
          specialArgs = {
            inherit inputs;
          };

          system = "aarch64-darwin";

          modules = [
            ./hosts/mallow

            # Nixpkgs overlays
            ({
              config,
              inputs,
              ...
            }: {
              nixpkgs = {
                config.allowUnfree = true;

                overlays = with overlays; [
                  inputs.nix-darwin.overlays.default
                  default
                  (unstable "aarch64-darwin")
                ];
              };
            })

            # Home-manager configuration
            ./home/darwin-module.nix

            ({
              config,
              inputs,
              pkgs,
              ...
            }: {
              programs.fish.enable = true;
              environment.shells = [pkgs.fish];
              users.users.dorchard = {
                home = "/Users/dorchard";
                uid = 503;
                gid = 20;
                shell = pkgs.fish;
              };
            })
          ];
        };
      };

      nixosConfigurations = with nixpkgs.lib; rec {
        pavil = nixosSystem {
          inherit specialArgs;

          system = "x86_64-linux";
          modules = defaultModules "pavil" {};
        };

        nib = nixosSystem {
          inherit specialArgs;

          system = "x86_64-linux";
          modules = defaultModules "nib" {};
        };

        cuttlefish = nixosSystem {
          inherit specialArgs;

          system = "x86_64-linux";
          modules = defaultModules "cuttlefish" {};
        };

        # https://mobile.nixos.org/devices/motorola-potter.html
        # - Test with: nix eval "/etc/nixos#nixosConfigurations.moto.config.system.build.toplevel.drvPath"
        # - Build with: nixos-rebuild build --flake path:///etc/nixos#moto
        moto = nixosSystem {
          inherit specialArgs;

          system = "aarch64-linux";
          modules =
            (defaultModules "moto" {})
            ++ [
              (import "${inputs.mobile-nixos}/lib/configuration.nix" {device = "motorola-potter";})
            ];
        };

        # Build with: `nix build 'path:.#nixosConfigurations.moto-image'`
        # Impure needed to access host paths without putting in the nix store
        moto-image = moto.config.mobile.outputs.android.android-fastboot-images;

        rpi3 = nixosSystem {
          inherit specialArgs;

          system = "aarch64-linux";
          modules =
            (defaultModules "rpi3" {})
            ++ [
              "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            ];
        };

        # Build with: `nix build --impure 'path:.#nixosConfigurations.rpi3-image'`
        # Impure needed to access host paths without putting in the nix store
        rpi3-image = rpi3.config.system.build.sdImage;

        drywell = nixosSystem {
          inherit specialArgs;

          system = "x86_64-linux";
          modules = defaultModules "drywell" {};
        };

        installer-test = nixosSystem {
          inherit specialArgs;

          system = "x86_64-linux";
          modules = defaultModules "installer-test" {};
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
          while [ ! -f "flake.nix" ] && [ "$PWD" != "/" ]; do
            cd ..
          done
        '';

        generate-hardware = ''
          config="hosts/$(hostname)/hardware/generated.nix"
          mkdir "$(dirname "$config")"
          touch "$config"

          # Must use `sudo` so that all mounts are visible
          sudo nixos-generate-config --show-hardware-config | \
            scripts/maintenance/process-hardware-config.awk > "$config"

          nix fmt "$config"
        '';

        generate-hardware-linux = system:
          nixpkgs.legacyPackages.${system}.writeShellApplication {
            name = "generate-hardware";
            text = ''
              ${change-to-flake-root}
              ${generate-hardware}
            '';
          };

        rebuild-linux = system:
          nixpkgs.legacyPackages.${system}.writeShellApplication {
            name = "rebuild";
            text = ''
              ${change-to-flake-root}
              ${generate-hardware}

              # Rebuild
              sudo nixos-rebuild switch

              # Format
              nix fmt
            '';
          };

        rebuild-darwin = system:
          nixpkgs.legacyPackages.${system}.writeShellApplication {
            name = "rebuild";
            text = ''
              ${change-to-flake-root}

              # Copy cert file already on the machine
              certSource="/etc/ssl/afscerts/ca-certificates.crt"
              if [ -f "$certSource" ]; then
                cp "$certSource" "hosts/mallow/ca-certificates.crt"
              fi

              # Rebuild
              darwin-rebuild switch --flake ".#$(hostname)"

              # Format
              nix fmt
            '';
          };
      in {
        x86_64-linux.rebuild = rebuild-linux "x86_64-linux";
        aarch64-linux.rebuild = rebuild-linux "aarch64-linux";

        x86_64-darwin.rebuild = rebuild-darwin "x86_64-darwin";
        aarch64-darwin.rebuild = rebuild-darwin "aarch64-darwin";
      };

      apps = inputs.flake-utils.lib.eachDefaultSystemMap (
        system: {
          default = {
            type = "app";
            program = "${packages.${system}.rebuild}/bin/rebuild";
          };

          generate-hardware = {
            type = "app";
            program = "${packages.${system}.generate-hardware}/bin/generate-hardware";
          };
        }
      );

      formatter = inputs.flake-utils.lib.eachDefaultSystemMap (system: nixpkgs.legacyPackages.${system}.alejandra);
    };
}
