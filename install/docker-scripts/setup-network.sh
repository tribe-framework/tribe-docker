#!/usr/bin/env bash

set -e

set_env_var() {
  local key=$1
  local value=$2
  local file=${3:-.env}

  if grep -q "^${key}=" "$file"; then
    # Update existing variable
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    # Append new variable
    echo "${key}=${value}" >> "$file"
  fi
}

NETWORK_NAME="auto_net_$RANDOM"
BASE="172.25"
PREFIX=29
MAX_SUBNETS=32  # gives 32 small /29 ranges within 172.25.0.0/24

# Get used subnets
USED_SUBNETS=$(docker network inspect $(docker network ls -q) 2>/dev/null \
  | grep -Eo '"Subnet":\s*"[^"]+"' \
  | awk -F'"' '{print $4}')

# Try candidate /29 subnets
FOUND_SUBNET=""
for i in $(seq 0 $((MAX_SUBNETS - 1))); do
  OCTET3=$((i / 8))
  OCTET4=$(( (i % 8) * 8 ))
  CANDIDATE="$BASE.$OCTET3.$OCTET4/$PREFIX"

  CONFLICT=false
  for used in $USED_SUBNETS; do
    if [[ "$used" == "$CANDIDATE" ]]; then
      CONFLICT=true
      break
    fi
  done

  if ! $CONFLICT; then
    FOUND_SUBNET=$CANDIDATE
    break
  fi
done

if [[ -z "$FOUND_SUBNET" ]]; then
  echo "❌ No available /29 subnet found in $BASE.0.0/16. Expand range or cleanup unused networks."
  exit 1
fi

echo "✅ Using compact subnet: $FOUND_SUBNET"

# Create the network
docker network create \
  --driver bridge \
  --subnet "$FOUND_SUBNET" \
  "$NETWORK_NAME"

# Export for Compose
export COMPOSE_NETWORK_NAME=$NETWORK_NAME
set_env_var "COMPOSE_NETWORK_NAME" "$NETWORK_NAME"
