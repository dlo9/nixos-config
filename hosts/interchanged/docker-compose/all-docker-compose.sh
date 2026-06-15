#!/bin/sh

if [ "$#" -eq 0 ]; then
  echo "Usage: all-docker-compose [docker compose options]"
  exit 1
fi

# Wait for the docker engine (colima service) to come up before touching compose
tries=0
until docker info >/dev/null 2>&1; do
  tries=$((tries + 1))
  [ "$tries" -gt 60 ] && { echo "docker engine not ready after 120s" >&2; break; }
  sleep 2
done

state_dir="$HOME/.local/state/docker-compose"
logs_dir="$state_dir/logs"

# Create logs directory if it doesn't exist
mkdir -p "$logs_dir"

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

    # Run docker-compose
    docker compose "$@" >> "$logs_dir/$dirname.stdout.log" 2>> "$logs_dir/$dirname.stderr.log" &
    printf "%s\n\n" "Done"
  fi

  # Return to the original directory
  cd ..
done

echo "All services done"
sleep 365d
