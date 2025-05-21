#!/usr/bin/env bash

set -e

source .env

# Must match the network name in your compose file
NETWORK_NAME=${COMPOSE_NETWORK_NAME:-auto_net_default}

echo "🔻 Bringing down Compose stack..."
docker compose down

# Check if the network exists and is unused
if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
  CONTAINERS=$(docker network inspect "$NETWORK_NAME" \
    | jq -r '.[0].Containers | keys | length')

  if [[ "$CONTAINERS" == "0" ]]; then
    echo "🧹 Removing unused network: $NETWORK_NAME"
    docker network rm "$NETWORK_NAME"
  else
    echo "⚠️ Network '$NETWORK_NAME' is still in use by containers."
  fi
else
  echo "ℹ️ Network '$NETWORK_NAME' not found or already removed."
fi
