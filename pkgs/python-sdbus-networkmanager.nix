{
  lib,
  python3,
  fetchPypi,
  #python-sdbus,
  dlo9,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "sdbus-networkmanager";
  version = "2.0.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-NXKsOoGJxoPsBBassUh2F3Oo8Iga09eLbW9oZO/5xQs=";
  };

  build-system = [
    python3.pkgs.setuptools
    python3.pkgs.wheel
  ];

  dependencies = with python3.pkgs; [
    dlo9.python-sdbus
  ];

  pythonImportsCheck = [
    "sdbus_block.networkmanager"
    #"sdbus_async.networkmanager"
  ];

  meta = {
    description = "NetworkManager binds for sdbus";
    homepage = "https://pypi.org/project/sdbus-networkmanager/";
    license = with lib.licenses; [gpl2Only lgpl21Only];
    maintainers = with lib.maintainers; [];
    mainProgram = "sdbus-networkmanager";
  };
}
