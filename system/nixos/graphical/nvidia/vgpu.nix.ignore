# WIP: Enable vGPU on nvidia cards
# Resources:
#  - https://wvthoog.nl/proxmox-7-vgpu-v2/#Mdevctl
#  - https://github.com/DualCoder/vgpu_unlock
#  - https://github.com/mbilker/vgpu_unlock-rs
#  - https://github.com/erin-allison/aur-packages/blob/master/nvidia-merged/PKGBUILD
#  - https://krutavshah.github.io/GPU_Virtualization-Wiki/installation/driver-customization.html#vgpu-kvm-driver
#  - https://cerberus.ciat.cgiar.org/
#  - https://cloud.google.com/compute/docs/gpus/grid-drivers-table
#  - https://docs.nvidia.com/grid/index.html

{ lib
, stdenv
, fetchFromGitHub
, fetchurl
, rustPlatform
, python3
, writeShellApplication
}:

stdenv.mkDerivation rec {
  pname = "nvidia-unlocked";
  version = "1.0.0";

  frida = python3.pkgs.buildPythonPackage rec {
    pname = "frida";
    version = "16.0.19";
    format = "wheel";

    disabled = python3.pythonOlder "3.7";

    propagatedBuildInputs = with python3.pkgs; [
      typing-extensions
    ];

    # src = fetchurl {
    #   url = "https://files.pythonhosted.org/packages/d0/4c/72e84a0bd0bf8d14005325097901a395824cc981be5ae1dde319014eec73/frida-16.0.19-cp37-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.whl";
    #   sha256 = "sha256-4TQUpj8TEHT8m1xeZIKvlNLtx+JneVrscY/LXKcegVQ=";
    # };

    src = python3.pkgs.fetchPypi rec {
      inherit pname version format;
      python = "cp37";
      abi = "abi3";
      platform = "manylinux_2_5_x86_64.manylinux1_x86_64";
      sha256 = "sha256-4TQUpj8TEHT8m1xeZIKvlNLtx+JneVrscY/LXKcegVQ=";
    };
  };

  vgpuUnlockSrc = fetchFromGitHub {
    owner = "DualCoder";
    repo = "vgpu_unlock";
    rev = "f432ffc8b7ed245df8858e9b38000d3b8f0352f4";
    sha256 = "sha256-o+8j82Ts8/tEREqpNbA5W329JXnwxfPNJoneNE8qcsU=";
  };

  vgpuUnlock = writeShellApplication rec {
    name = "vgu_unlock";

    runtimeInputs = [
      (python3.withPackages (ps: [ frida ]))
    ];

    text = "python ${vgpuUnlockSrc}/vgpu_unlock";
  };

  driver = fetchurl {
    url = "https://www.dropbox.com/s/vfspua0abgd4ef6/NVIDIA-Linux-x86_64-460.73.01-grid-vgpu-kvm-v5.run?dl=0";
    sha256 = "sha256-cYGxTd8RjfizV3KnRG473eoWMjEVWh8Srdf4jms41pc=";
  };

  gpuUnlockRs = rustPlatform.buildRustPackage rec {
    pname = "vgpu_unlock-rs";
    version = "44d5bb32ecd8bdcfe374772c31078a6e4eef921f";

    src = fetchFromGitHub {
      owner = "mbilker";
      repo = "vgpu_unlock-rs";
      rev = version;
      sha256 = "sha256-0NPGk35tCgAYWbfs4FG9/p6RuvqUY1L33sobMSIeh/s=";
    };

    cargoPatches = [ ./vgpu_unlock-rs.patch ];
    cargoHash = "sha256-TJGFQbgrMsGa4OlQP6v6bQctuRJc/anzpj9jXaW0uqk=";
  };

  srcs = [
    frida
    vgpuUnlock+
    driver
    gpuUnlockRs
  ];

  # meta = with lib; {
  #   description = "Sunshine is a Game stream host for Moonlight.";
  #   homepage = "https://github.com/LizardByte/Sunshine";
  #   license = licenses.gpl3Only;
  #   maintainers = with maintainers; [ devusb ];

  #   platforms = platforms.linux;
  # };
}
