{ pkgs, lib }:

rec {
    fromYAMLString = yamlString: (fromYAML (builtins.toFile "from-yaml-string" yamlString));

    fromYAML = yamlFile: builtins.fromJSON (
      builtins.readFile (
        pkgs.runCommand "from-yaml"
          {
            allowSubstitutes = false;
            preferLocalBuild = true;
          }
          ''
            ${pkgs.yj}/bin/yj -yj < "${yamlFile}" > "$out"
          ''
      )
    );
  }
