{
  lib,
  python3,
  fetchPypi,
  pkg-config,
  systemd,
  #python-sdbus-networkmanager,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "sdbus";
  version = "0.13.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-gBvUZgjugmFNQpYMi6iukwDtsb9bvrU0vI/SHxPSwg4=";
  };

  build-system = [
    python3.pkgs.setuptools
    python3.pkgs.wheel
  ];

  #pythonPath = [
  #  python-sdbus-networkmanager
  #];

  pythonImportsCheck = [
    "sdbus"
  ];

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    systemd
  ];

  meta = {
    description = "Modern Python D-Bus library. Based on sd-bus from libsystemd";
    homepage = "https://pypi.org/project/sdbus/";
    license = with lib.licenses; [ gpl2Only lgpl21Only ];
    maintainers = with lib.maintainers; [ ];
    mainProgram = "sdbus";
  };
}
