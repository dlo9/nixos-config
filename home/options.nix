{
  config,
  pkgs,
  lib,
  inputs,
  osConfig,
  ...
}:
with lib;
with types;
with builtins; {
  options = {
    graphical.enable = mkEnableOption "graphical programs" // {default = osConfig.graphical.enable;};

    developer-tools.enable = mkEnableOption "developer tools" // {default = osConfig.developer-tools.enable;};

    font.family = mkOption {
      type = nonEmptyStr;
      default = osConfig.font.family;
    };

    font.size = mkOption {
      type = ints.positive;
      default = osConfig.font.size;
    };

    wallpapers = mkOption {
      type = attrsOf package;
      readOnly = true;

      default = rec {
        default = spaceman;

        spaceman = fetchurl {
          name = "spaceman";
          url = https://forum.endeavouros.com/uploads/default/original/3X/c/d/cdb27eeb063270f9529fae6e87e16fa350bed357.jpeg;
          sha256 = "02b892xxwyzzl2xyracnjhhvxvyya4qkwpaq7skn7blg51n56yz2";
        };

        #valley = fetchurl {
        #  name = "elementary-os-7";
        #  url = https://raw.githubusercontent.com/elementary/wallpapers/3f36a60cbb9b8b2a37d0bc5129365ac2ac7acf98/backgrounds/Photo%20of%20Valley.jpg;
        #  sha256 = "0xvdyg4wa1489h5z6p336v5bk2pi2aj0wpsp2hdc0x6j4zpxma7k";
        #};

        # Hash keeps changing
        #pink-sunset = fetchurl {
        #  name = "pink-sunset";
        #  url = https://cutewallpaper.org/22/retro-neon-race-4k-wallpapers/285729412.jpg;
        #  sha256 = "0p6z31gh552rk4w99gbvr3hvwadfrv6h97k41qdbb9mxy7wc9brz";
        #};

        #mountain-milky-way = fetchurl {
        #  name = "mountain-milky-way";
        #  url = https://images.squarespace-cdn.com/content/v1/5de93a2db580764b4f6963f9/10757377-0072-4864-bcf9-17bc4df0d252/GOLD%C2%A9Jake+Mosher_The+Grand+Tetons.jpg;
        #  sha256 = "19l11x94qyc7mqwkrr8l2llimqp7v38ikd66k3pvma0vb3773js3";
        #};

        #mountain-reflection = fetchurl {
        #  name = "mountain-reflection";
        #  url = https://images.squarespace-cdn.com/content/v1/5de93a2db580764b4f6963f9/956426d5-8a84-493d-af76-fee19de5a29d/SILVER%C2%A9Beatrice+Wong_Parallel+universe.jpg;
        #  sha256 = "173spa2j1fbvgzag3lw3y3sl7zpags4mixrwx7fv0brmp483v8g7";
        #};

        # Blocked by cloudflare
        #wr-134-wolf-nebula = fetchurl {
        #  name = "";
        #  url = https://media.invisioncic.com/r307508/monthly_2024_09/WR134HOO.jpg.6a54efbab22a1e32d98ab035856280ab.jpg;
        #  sha256 = "38271ff1945e3c717a29b242919326cd014dea8b99932fa3262adccc622e8f9b";
        #};
      };
    };
  };
}
