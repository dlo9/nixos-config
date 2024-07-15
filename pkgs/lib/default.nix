{
  callPackage,
  lib,
  formats,
}: rec {
  fromYAML = callPackage ./fromYAML.nix {};
  fromYAMLString = callPackage ./fromYAMLString.nix {};
  jsonTrace = value: builtins.trace (builtins.toJSON value) value;

  ext = path: lib.last (lib.splitString "." path);

  xdgSerdes = {
    toml = (formats.toml {}).generate;
    yml = (formats.yaml {}).generate;
    yaml = (formats.yaml {}).generate;
  };

  xdgSerde = path: xdgSerdes."${ext path}" path;

  xdgFile = path: value: {
    name = path;
    value.source = xdgSerde path value;
  };

  maintainers.dlo9 = {
    email = "if_coding@fastmail.com";
    github = "dlo9";
    githubId = 7187117;
    name = "David Orchard";
  };
}
