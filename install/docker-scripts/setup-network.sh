#!/usr/bin/env bash

set -e

# Configuration
CIDR_BASE_START=16   # 172.80.x.x
CIDR_BASE_END=31     # 172.95.x.x
SUBNET_PREFIX=29     # /29 = 8 IPs (5 usable)
ENV_FILE=".env"

# Util: Write or update key in .env
set_env_var() {
  local key=$1
  local value=$2
  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

# Fetch all used subnets
USED_SUBNETS=$(docker network inspect $(docker network ls -q) 2>/dev/null \
  | grep -Eo '"Subnet":\s*"[^"]+"' \
  | awk -F'"' '{print $4}')

# Try all possible /29s within the 172.80.0.0/12 range
FOUND_SUBNET=""
for i in $(seq $CIDR_BASE_START $CIDR_BASE_END); do
  for j in $(seq 0 255); do
    for k in $(seq 0 248 8); do
      CANDIDATE="172.${i}.${j}.${k}/${SUBNET_PREFIX}"
      CONFLICT=false
      for used in $USED_SUBNETS; do
        if [[ "$used" == "$CANDIDATE" ]]; then
          CONFLICT=true
          break
        fi
      done
      if ! $CONFLICT; then
        FOUND_SUBNET=$CANDIDATE
        break 3
      fi
    done
  done
done

if [[ -z "$FOUND_SUBNET" ]]; then
  echo "❌ No available subnet found in 172.80.0.0/12. Expand your range or clean up unused networks."
  exit 1
fi

echo "✅ Allocating network subnet $FOUND_SUBNET"

# Save network name for Compose
set_env_var "DOCKER_SUBNET" "$FOUND_SUBNET"

# Run your Compose stack
docker compose up -d

echo "✅ Network created and Compose stack is running."
