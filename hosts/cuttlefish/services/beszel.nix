{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins; {
  systemd.services.beszel = {
    description = "Bazel Monitoring Hub";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "beszel-hub";

      ExecStart = "${pkgs.beszel}/bin/beszel-hub --dir $STATE_DIRECTORY serve --http localhost:8090";
    };
  };

  systemd.services.beszel-agent = {
    description = "Bazel Monitoring Agent";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    environment = {
      PORT = "45876";
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPw0sHO8BjxrL+fJFX1p3TqKdXAhc7nz9ujotfRdxzpw";
    };

    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "beszel-agent";
      ReadOnlyPaths = ["/var/run/docker.sock"];

      KeyringMode = "private";
      LockPersonality = "yes";
      NoNewPrivileges = "yes";
      PrivateTmp = "yes";
      ProtectClock = "yes";
      ProtectHome = "read-only";
      ProtectHostname = "yes";
      ProtectKernelLogs = "yes";
      ProtectKernelTunables = "yes";
      ProtectSystem = "strict";
      RemoveIPC = "yes";
      RestrictSUIDSGID = "true";
      SystemCallArchitectures = "native";

      ExecStart = "${pkgs.beszel}/bin/beszel-agent";
    };
  };
}
