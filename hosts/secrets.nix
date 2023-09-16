{
  lib,
  pkgs,
  ...
}:
with lib;
with types; let
  hosts = attrNames (filterAttrs (n: v: v == "directory") (readDir ./.));

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
in {
  config.sops.secrets = builtins.listToAttrs (
    map (host: {
      name = host;
      value = importSecrets "./${host}/secrets.yaml";
    })
    hosts
  );
}
