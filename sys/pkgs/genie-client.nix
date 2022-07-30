#with import <nixpkgs> {};

{ lib
, stdenv
, fetchFromGitHub
, meson
, ninja
, pkg-config
, cmake
, alsa-lib
, glib
, libsoup
, json-glib
, libevdev
, gst_all_1
, speex
, speexdsp
, webrtc-audio-processing
, libpulseaudio
, sound-theme-freedesktop
}:

stdenv.mkDerivation rec {
  pname = "genie-client";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "stanford-oval";
    repo = pname;
    rev = "v${version}";
    fetchSubmodules = true;
    sha256 = "sha256-JIaePTZsWV6BqipzkM45WByikMwsLIeTk+N+hxyTvUQ=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    cmake
  ];

  buildInputs = [
    alsa-lib
    glib
    libsoup
    json-glib
    libevdev
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    #gst_all_1.libav
    speex
    speexdsp
    webrtc-audio-processing
    libpulseaudio
  ];

  postPatch = ''
    assetScript="./scripts/get-assets.sh"
    substituteInPlace "$assetScript" --replace '/usr/share/sounds/freedesktop' '${sound-theme-freedesktop}/share/sounds/freedesktop'
    patchShebangs "$assetScript"
    "$assetScript"
  '';

  meta = with lib; {
    description = "This is a light-weight client for the Genie Web API";
    homepage = "https://github.com/stanford-oval/genie-client";
    license = licenses.asl20;
    # maintainers = with maintainers; [ dlo9 ];
    platforms = [ "x86_64-linux" "armv7l-linux" "aarch64-linux" ];
  };
}
