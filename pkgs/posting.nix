{
  python3Packages,
  fetchPypi,
  fetchFromGitHub,
}: let
  py = python3Packages.override {
    overrides = final: prev:
      with prev; {
        textual-autocomplete = buildPythonApplication rec {
          pname = "textual_autocomplete";
          version = "3.0.0a9";
          pyproject = true;
          pythonRelaxDeps = true;
          disabled = pythonOlder "3.8";

          src = fetchPypi {
            inherit pname version;
            hash = "sha256-tfPjFIt5Pxcq/mQ6WyGIxewU/LQrY5uYsjExwn5S3oU=";
          };

          build-system = [
            poetry-core
          ];

          dependencies = [
            textual
            typing-extensions
          ];

          nativeBuildInputs = [
            pythonRelaxDepsHook
          ];
        };
      };
  };
in
  with py;
    buildPythonApplication rec {
      pname = "posting";
      version = "1.12.3";
      pyproject = true;
      pythonRelaxDeps = true;
      disabled = pythonOlder "3.8";

      src = fetchPypi {
        inherit pname version;
        hash = "sha256-MehpRuiwuQ2oRq3ayk3Oz3VMC/q2yq5RqDdPCwXIfhg=";
      };

      build-system = [
        hatchling
      ];

      dependencies = [
        click-default-group
        click
        httpx
        pydantic-settings
        pydantic
        pyperclip
        python-dotenv
        pyyaml
        textual-autocomplete
        textual
        xdg-base-dirs
      ];

      nativeBuildInputs = [
        pythonRelaxDepsHook
      ];
    }
