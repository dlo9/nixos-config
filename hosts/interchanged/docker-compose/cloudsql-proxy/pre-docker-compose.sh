#!/bin/sh

set -e

# List of projects to get the database connection names from
projects="
  apex-trade-processing-dev-00
  apex-trade-processing-stg-00
  apex-trade-processing-uat-00
  apex-trade-processing-prd-00
  apex-trade-processing-sbx-00
  apex-trade-processing-rcn-00
"

# Get the credentials path
credentials_file="$(gcloud info --format='value(config.paths.global_config_dir)')/application_default_credentials.json"

# Write env file
env_file="$PWD/.env"

cat << EOF > "$env_file"
CSQL_PROXY_PRIVATE_IP=true
CSQL_PROXY_AUTO_IAM_AUTHN=true
CSQL_PROXY_CREDENTIALS_FILE=$credentials_file
EOF

# Add databases to env file
i=0
for project in $projects; do
  databases="$(gcloud sql instances list --project $project --format='value(connectionName)')"
  for database in $databases; do
    echo "CSQL_PROXY_INSTANCE_CONNECTION_NAME_$i: $database" >> "$env_file"
    i=$((i + 1))
  done
done
