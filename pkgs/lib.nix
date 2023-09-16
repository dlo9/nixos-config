{
  pkgs,
  lib,
}: rec {
  fromYAMLString = yamlString: (fromYAML (builtins.toFile "from-yaml-string" yamlString));

  fromYAML = yamlFile:
    builtins.fromJSON (
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

  importSecrets = sopsFile: let
    fileToSecrets = mapAttrs' (
      key: value:
        if (builtins.isAttrs value && (value.enable ? false))
        then {"${key}/contents" = value.attrs // {inherit sopsFile;};}
        else null
    );
    removeNulls = filterAttrs (name: value: value != null);
    contents = fromYAML sopsFile;
  in
    removeNulls (fileToSecrets contents);

  importExports = sopsFile: let
    fileToExports = mapAttrs' (
      key: value:
        if (builtins.isAttrs value && (value.enable ? false))
        then (value.exports ? {})
        else {}
    );
    removeNulls = filterAttrs (name: value: value != null);
    contents = fromYAML sopsFile;
  in
    removeNulls (fileToExports contents);
}
