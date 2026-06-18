#!/bin/sh

if [ "$#" -eq 0 ]; then
  echo "Usage: all-docker-compose [docker compose options]"
  exit 1
fi

# `docker` here is the podman wrapper. Expose the VM user's uid (= host uid) for the
# traefik socket-mount path; derived at runtime so nothing is hard-coded.
export PODMAN_UID="$(id -u)"

# Wait for the docker engine (podman machine) to come up before touching compose
tries=0
until docker info >/dev/null 2>&1; do
  tries=$((tries + 1))
  [ "$tries" -gt 60 ] && { echo "docker engine not ready after 120s" >&2; break; }
  sleep 2
done

# The Go docker-compose provider (podman's external compose backend) connects via
# DOCKER_HOST. Under launchd we don't inherit the interactive shell's DOCKER_HOST,
# and the podman-machine API socket lives under the per-user Darwin temp dir — its
# path is deterministic via getconf, independent of any inherited (or absent) TMPDIR.
tmp="$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null)"
[ -S "${tmp}podman/podman-machine-default-api.sock" ] &&
  export DOCKER_HOST="unix://${tmp}podman/podman-machine-default-api.sock"

# Rootless podman can't bind privileged ports (e.g. traefik's :80) without raising the
# unprivileged-port floor inside the VM. Idempotent + persisted; re-applied each startup
# so it survives a machine recreate. No-op when podman isn't the engine.
if command -v podman >/dev/null 2>&1; then
  podman machine ssh -- \
    'echo net.ipv4.ip_unprivileged_port_start=80 | sudo tee /etc/sysctl.d/99-unprivileged-ports.conf >/dev/null && sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80 >/dev/null' \
    2>/dev/null || true
fi

state_dir="$HOME/.local/state/docker-compose"
logs_dir="$state_dir/logs"

# Create logs directory if it doesn't exist
mkdir -p "$logs_dir"

# Create network up-front so startup order doesn't matter
docker network inspect traefik_shared >/dev/null 2>&1 || docker network create traefik_shared

# Tear down every compose project on stop, so the detached (`up -d`) containers don't
# outlive the launchd agent. Mirrors the startup loop's project selection.
teardown() {
  echo "Stopping compose services..."
  for d in */; do
    [ -f "${d}.ignore" ] && continue
    [ -f "${d}docker-compose.yaml" ] || [ -f "${d}docker-compose.yml" ] || continue
    name="${d%/}"
    ( cd "$d" && docker compose down ) >> "$logs_dir/$name.stdout.log" 2>> "$logs_dir/$name.stderr.log"
    echo "$name: stopped"
  done
  echo "All services stopped"
}

# For the resident `up` flow, tear down on stop (launchd SIGTERM / Ctrl-C). Installed
# before the loop so a stop mid-startup still cleans up partially-started services.
if [ "$1" = "up" ]; then
  trap 'teardown; kill "${sleep_pid:-}" 2>/dev/null; exit 0' TERM INT
fi

# Use read with find to process directories
find . -type d -depth 1 | while read -r d; do
  # Extract directory name without path
  dirname=$(basename "$d")

  # Change to the directory
  cd "$d" || continue

  if [ -f ".ignore" ]; then
    printf "%s\n" "Skipping $dirname $@... "
    cd ..
    continue
  fi

  if [ -f "docker-compose.yaml" ] || [ -f "docker-compose.yml" ]; then
    printf "%s\n" "Running $dirname $@... "

    if [ -f "pre-docker-compose.sh" ]; then
      # Run the custom startup script
      if ./pre-docker-compose.sh; then
        printf "%s\n" "pre-start script executed successfully."
      else
        printf "%s\n" "Error executing pre-docker-compose script"
      fi
    fi

    if [ "$1" = "up" ]; then
      # Start detached so we get a real exit status; an attached `up` would block
      # the loop forever. Report failures instead of always printing "Done".
      if docker compose "$@" -d >> "$logs_dir/$dirname.stdout.log" 2>> "$logs_dir/$dirname.stderr.log"; then
        printf "%s\n\n" "$dirname: started"
        # Stream container logs in the background for debugging
        docker compose logs -f >> "$logs_dir/$dirname.stdout.log" 2>> "$logs_dir/$dirname.stderr.log" &
      else
        rc=$?
        printf "%s\n\n" "$dirname: FAILED (exit $rc) -- see logs/$dirname.stderr.log"
      fi
    else
      docker compose "$@" >> "$logs_dir/$dirname.stdout.log" 2>> "$logs_dir/$dirname.stderr.log"
      printf "%s: exit %s\n\n" "$dirname" "$?"
    fi
  fi

  # Return to the original directory
  cd ..
done

echo "All services done"

# Stay resident for the `up` flow so the trap (installed above) can fire on stop; wait
# on a backgrounded sleep so the signal interrupts promptly. Other invocations (e.g.
# `down`) just exit. launchd's ExitTimeOut must allow time for the teardown.
if [ "$1" = "up" ]; then
  sleep 365d &
  sleep_pid=$!
  wait "$sleep_pid"
fi
