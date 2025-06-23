{
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}:
with lib; {
  imports = [
    "${inputs.self}/home"
    ./home/mail.nix
  ];

  home.stateVersion = "22.05";

  # SSH
  home.file = {
    ".ssh/id_ed25519.pub".text = osConfig.hosts.${osConfig.networking.hostName}.david-ssh-key.pub;
  };

  home.packages = with pkgs; [
    nvtopPackages.intel # GPU monitoring
    kdash # kubernetes dashboard
  ];

  # wivrn
  # https://github.com/WiVRn/WiVRn/issues/45#issue-2165564488
  # xdg.configFile."openxr/1/active_runtime.json".text = ''
  #   {
  #     "file_format_version": "1.0.0",
  #     "runtime": {
  #         "name": "wivrn",
  #         "library_path": "${osConfig.services.wivrn.package}/lib/wivrn/libopenxr_wivrn.so"
  #     }
  #   }
  # '';

  # VR
  xdg.configFile."wlxoverlay/conf.d/pw_fallback.yaml".text = ''
    capture_method: pw_fallback
  '';

  xdg.configFile."openxr/1/active_runtime.json".source = "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json";

  xdg.configFile."openvr/openvrpaths.vrpath".text = builtins.toJSON {
    config = ["${config.xdg.dataHome}/Steam/config"];
    external_drivers = null;
    jsonid = "vrpathreg";
    logs = ["${config.xdg.dataHome}/Steam/logs"];
    runtime = ["${pkgs.opencomposite}/lib/opencomposite"];
    version = 1;
  };
}
