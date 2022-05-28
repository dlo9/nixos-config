{ config, pkgs, lib, ... }:

# Gererate GitHub packages with: /etc/nixos/scripts/util/pkg-gen.sh owner repo rev

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.pkgs;

  dlo9 = {
    email = "if_coding@fastmail.com";
    github = "dlo9";
    githubId = 7187117;
    name = "David Orchard";
  };
in
{
  options.sys.pkgs = mkOption {
    description = "Custom packages";
    type = types.attrsOf types.package;
    default = {
      ###############
      ##### VIM #####
      ###############

      vim-yadi = pkgs.vimUtils.buildVimPlugin {
        name = "vim-yadi";
        src = pkgs.fetchFromGitHub {
          owner = "timakro";
          repo = "vim-yadi";
          rev = "d868366707bfc966f856347828607f92bc5cd9fb";
          sha256 = "0c34y7w31vg2qijprhnd0dakmqasaiflrkh54iv8shn79l7cvhsm";
        };
      };

      coc-rome = pkgs.vimUtils.buildVimPlugin {
        name = "coc-rome";
        src = pkgs.fetchFromGitHub {
          owner = "fannheyward";
          repo = "coc-rome";
          rev = "b14e08e942997ca202037efb7ed72506f761fca5";
          sha256 = "0l7aff25hhsdkpybcvqnn46z9izzrbldyw6ljri8smbfvipaaz5y";
        };
      };

      coc-sh = pkgs.vimUtils.buildVimPlugin {
        name = "coc-sh";
        src = pkgs.fetchFromGitHub {
          owner = "josa42";
          repo = "coc-sh";
          rev = "c3d808d7a0bf20d999c2ab84f899133cfdfaffc2";
          sha256 = "0lvjbi7bfx8r7l10hlysq8jjfb2wv70db3gsqf67rc1d15p4n7nm";
        };
      };

      coc-docker = pkgs.vimUtils.buildVimPlugin {
        name = "coc-docker";
        src = pkgs.fetchFromGitHub {
          owner = "josa42";
          repo = "coc-docker";
          rev = "fd949be7a0178c6d5358f6ccf4f6b73c6fc181b2";
          sha256 = "0b4hk85wvvzd5a628kp2lk45bxqj7q2fsrhfkvd36cnhwc262zml";
        };
      };

      #################
      ##### OTHER #####
      #################

      tmux-themepack = pkgs.tmuxPlugins.mkTmuxPlugin {
        pluginName = "tmux-themepack";
        rtpFilePath = "themepack.tmux";
        version = "unstable-2022-05-18";
        src = pkgs.fetchFromGitHub {
          owner = "jimeh";
          repo = "tmux-themepack";
          rev = "7c59902f64dcd7ea356e891274b21144d1ea5948";
          sha256 = "1kl93d0b28f4gn1knvbb248xw4vzb0f14hma9kba3blwn830d4bk";
        };
      };

      flatcolor-gtk-theme = pkgs.stdenv.mkDerivation {
        pname = "flatcolor-gtk-theme";
        version = "2022-05-28";

        src = pkgs.fetchFromGitHub {
          owner = "jasperro";
          repo = "FlatColor";
          rev = "0a56c50e8c5e2ad35f6174c19a00e01b30874074";
          sha256 = "0pv3fmvs8bfkn5fwyg9z8fszknmca4sjs3210k15lrrx75hngi1z";
        };

        installPhase = ''
          rm .gitignore README.md
          sed -i 's/Polar Night/FlatColor/' index.theme

          mkdir -p $out/share/themes
          cp -r . $out/share/themes/FlatColor

          runHook postInstall
        '';

        meta = with lib; {
          description = "This is a simple gtk3 theme based on FlatColor by deviantfero";
          homepage = "https://github.com/jasperro/FlatColor";
          license = licenses.gpl3Only;
          platforms = platforms.unix;
          maintainers = [ dlo9 ];
        };
      };
    };
  };
}
