# Alternate method
docker run \
  -v "$(gcloud info --format='value(config.paths.global_config_dir)')/application_default_credentials.json:/application_default_credentials.json" \
  -p 5432:5432 \
  gcr.io/cloud-sql-connectors/cloud-sql-proxy \
  --credentials-file /application_default_credentials.json \
  --private-ip \
  --auto-iam-authn \
  $(gcloud sql instances list --project apex-trade-processing-dev-00 --format='value(connectionName)') \
  $(gcloud sql instances list --project apex-trade-processing-stg-00 --format='value(connectionName)') \
  $(gcloud sql instances list --project apex-trade-processing-uat-00 --format='value(connectionName)') \
  $(gcloud sql instances list --project apex-trade-processing-prd-00 --format='value(connectionName)')
