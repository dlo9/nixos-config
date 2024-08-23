{
  pkgs,
  lib,
  ...
}:
with lib; {
  # ondemand isn't supported since the amd-pstate driver is in use
  # https://www.reddit.com/r/linux/comments/15p4bfs/amd_pstate_and_amd_pstate_epp_scaling_driver
  powerManagement.cpuFreqGovernor = "powersave";
  systemd.services.cpufreq.serviceConfig.ExecStartPost = ''/bin/sh -c 'echo "power" | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference' '';
}
