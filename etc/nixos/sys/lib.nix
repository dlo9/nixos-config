{ config, pkgs, lib, ... }:

# Gererate GitHub packages with: /etc/nixos/scripts/util/pkg-gen.sh owner repo rev

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.lib;
in
{
  options.sys.lib = mkOption {
    description = "Library functions";
    type = types.attrsOf (types.functionTo types.anything);
    default = {
      fromYAML = yamlFile: builtins.fromJSON (
        builtins.readFile (
          pkgs.runCommandNoCC "from-yaml"
            {
              allowSubstitutes = false;
              preferLocalBuild = true;
            }
            ''
              ${pkgs.yj}/bin/yj -yj < "${yamlFile}" > "$out"
            ''
        )
      );
    };
  };
}
