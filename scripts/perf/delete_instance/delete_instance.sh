#!/bin/bash
set -e

VAULT_TOKEN=$(cat /etc/vault-token-dsde)

DOCKER_ETC_PATH=/usr/share/etc

mkdir -p mnt

# Read the service account credentials from vault:
docker run --rm -e VAULT_TOKEN=$VAULT_TOKEN broadinstitute/dsde-toolbox vault read -format=json secret/dsp/cromwell/perf/service-account-deployer | jq -r '.data.service_account' > mnt/sa.json

# The cloning itself sometimes takes a long time and the clone command errors out when that happens.
# Instead use the --async flag in the clone command above and then explicitly wait for the operation to be done. Timeout 15 minutes
docker run --name perf_sql_delete_gcloud_${BUILD_NUMBER} \
  -v "$(pwd)"/mnt:$DOCKER_ETC_PATH \
  -e DOCKER_ETC_PATH="${DOCKER_ETC_PATH}" \
  -e CROMWELL_INSTANCE_NAME="${CROMWELL_INSTANCE_NAME}" \
  --rm \
  google/cloud-sdk:slim /bin/bash -c " \
    gcloud auth activate-service-account --key-file ${DOCKER_ETC_PATH}/sa.json && \
    gcloud \
      --verbosity info \
      --project broad-dsde-cromwell-perf \
      --zone=us-central1-c \
      compute instances delete ${CROMWELL_INSTANCE_NAME}"
