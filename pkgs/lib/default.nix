{
  callPackage,
  lib,
  formats,
}: rec {
  fromYAML = callPackage ./fromYAML.nix {};
  fromYAMLString = callPackage ./fromYAMLString.nix {};
  jsonTrace = value: builtins.trace (builtins.toJSON value) value;

  ext = path: lib.last (lib.splitString "." path);

  # AttrSet of extention to convertion function
  serdes = rec {
    toml = (formats.toml {}).generate;
    yaml = (formats.yaml {}).generate;
    yml = yaml;
  };

  # Returns a convertion function for the given path
  serdeFromFilename = path: serdes."${ext path}" path;

  xdgFiles = lib.mapAttrs (path: value: {source = serdeFromFilename path value;});

  maintainers.dlo9 = {
    email = "if_coding@fastmail.com";
    github = "dlo9";
    githubId = 7187117;
    name = "David Orchard";
  };
}
