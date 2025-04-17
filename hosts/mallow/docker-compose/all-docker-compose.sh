#!/bin/sh

if [ "$#" -eq 0 ]; then
  echo "Usage: all-docker-compose [docker compose options]"
  exit 1
fi


# Create logs directory if it doesn't exist
mkdir -p logs

# Use read with find to process directories
find . -type d -depth 1 | while read -r d; do
  # Extract directory name without path
  dirname=$(basename "$d")

  # Change to the directory
  cd "$d" || continue

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
    docker compose "$@" >> "../logs/$dirname.stdout.log" 2>> "../logs/$dirname.stderr.log" &
    printf "%s\n\n" "Done"
  fi

  # Return to the original directory
  cd ..
done

echo "All services done"
sleep 365d
