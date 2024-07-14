{
  python3Packages,
  fetchPypi,
  fetchFromGitHub,
}: let
  py = python3Packages.override {
    overrides = final: prev: {
      textual = prev.textual.overridePythonAttrs (old: rec {
        version = "0.1.18";

        pythonRelaxDeps = [
          "rich"
        ];

        nativeBuildInputs = [
          prev.pythonRelaxDepsHook
        ];

        src = fetchFromGitHub {
          owner = "Textualize";
          repo = "textual";
          rev = "refs/tags/v${version}";
          hash = "sha256-XVmbt8r5HL8r64ISdJozmM+9HuyvqbpdejWICzFnfiw=";
        };

        doCheck = false;
      });
    };
  };
in
  with py;
    buildPythonApplication rec {
      pname = "tiptop";
      version = "0.2.8";
      pyproject = true;
      pythonRelaxDeps = true;
      disabled = pythonOlder "3.7";

      src = fetchPypi {
        inherit pname version;
        hash = "sha256-GpTStC2jM7rc6mDFfXoWyeV9C3q3IzRUFgUieaXpRfg=";
      };

      build-system = [
        setuptools
        wheel
      ];

      dependencies = [
        py-cpuinfo
        distro
        psutil
        rich
        textual
      ];

      nativeBuildInputs = [
        pythonRelaxDepsHook
      ];
    }
