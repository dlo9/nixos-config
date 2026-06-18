#!/bin/sh

if [ "$#" -eq 0 ]; then
  echo "Usage: all-docker-compose [docker compose options]"
  exit 1
fi

# `docker` here is the podman wrapper, which talks to the podman machine via its own
# connection (no DOCKER_HOST needed). Only expose the VM user's uid (= host uid) for
# the traefik socket-mount path; derived at runtime so nothing is hard-coded.
export PODMAN_UID="$(id -u)"

# Wait for the docker engine (podman machine) to come up before touching compose
tries=0
until docker info >/dev/null 2>&1; do
  tries=$((tries + 1))
  [ "$tries" -gt 60 ] && { echo "docker engine not ready after 120s" >&2; break; }
  sleep 2
done

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
sleep 365d
