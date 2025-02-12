#!/usr/bin/env bash

GREEN="\e[32m"
RESET="\e[0m"

## deploy the app
if [[ $1 == "deploy"]]; then
    chown -R www-data: *

    docker compose up -d

    sleep 30

    docker exec -i {$DB_HOST} mysql -u{$DB_USER} -p{$DB_PASS} {$DB_NAME} < {$APP_PATH}/tribe/install/db.sql
    while [ $? -eq 1 ]; do
        docker exec -i {$DB_HOST} mysql -u{$DB_USER} -p{$DB_PASS} {$DB_NAME} < {$APP_PATH}/tribe/install/db.sql
        sleep 2
    done

    exit
fi

read -p "Application name: " APP_NAME
read -p "Application unique ID (without spaces): " APP_UID

read -p "Database name: " DB_NAME
read -p "Database user: " DB_USER
read -p "Database password: " DB_PASS

read -p "Port for Tribe: " TRIBE_PORT
read -p "Port for Junction: " JUNCTION_PORT

read -p "Junction password: " JUNCTION_PASS
read -p "Domain for APP: " APP_DOMAIN
read -p "Enable HTTPS for Tribe? (y/n): " ENABLE_SSL

# randomly generated secret for TRIBE_API
TRIBE_API_SECRET=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)

DB_HOST="$APP_UID-db"
DOCKER_EXTERNAL_TRIBE_URL="localhost:$TRIBE_PORT"
DOCKER_EXTERNAL_JUNCTION_URL="localhost:$JUNCTION_PORT"

# Setup Tribe's bare and http/s urls
APP_DOMAIN=${APP_DOMAIN#http://}
APP_DOMAIN=${APP_DOMAIN#https://}

WEB_BARE_URL="tribe.$APP_DOMAIN"
JUNCTION_URL="junction.$APP_DOMAIN"

if echo "$ENABLE_SSL" | grep -iq "^y$"; then
    WEB_URL="https://$WEB_BARE_URL"
    JUNCTION_URL="https://$JUNCTION_URL"
else
    WEB_BARE_URL="http://$WEB_BARE_URL"
    JUNCTION_URL="http://$JUNCTION_URL"
fi

## Start updating files with user input
# docker-compose.yml
echo "Updating docker-compose.yml"
sed -i "s|\$APP_UID|$APP_UID|g" docker-compose.yml
sed -i "s|\$DB_USER|$DB_USER|g" docker-compose.yml
sed -i "s|\$DB_PASS|$DB_PASS|g" docker-compose.yml
sed -i "s|\$DB_NAME|$DB_NAME|g" docker-compose.yml
sed -i "s|\$TRIBE_PORT|$TRIBE_PORT|g" docker-compose.yml
sed -i "s|\$JUNCTION_PORT|$JUNCTION_PORT|g" docker-compose.yml

# .env file
echo "Setting up environment for tribe"
cp tribe/.env.sample tribe/.env
sed -i "s|\$APP_NAME|$APP_NAME|g" tribe/.env
sed -i "s|\$JUNCTION_PASS|$JUNCTION_PASS|g" tribe/.env
sed -i "s|\$WEB_BARE_URL|$WEB_BARE_URL|g" tribe/.env
sed -i "s|\$JUNCTION_URL|$JUNCTION_URL|g" tribe/.env
sed -i "s|\$APP_UID|$APP_UID|g" tribe/.env
sed -i "s|\$DOCKER_EXTERNAL_TRIBE_URL|$DOCKER_EXTERNAL_TRIBE_URL|g" tribe/.env
sed -i "s|\$DOCKER_EXTERNAL_JUNCTION_URL|$DOCKER_EXTERNAL_JUNCTION_URL|g" tribe/.env
sed -i "s|\$DB_NAME|$DB_NAME|g" tribe/.env
sed -i "s|\$DB_USER|$DB_USER|g" tribe/.env
sed -i "s|\$DB_PASS|$DB_PASS|g" tribe/.env
sed -i "s|\$DB_HOST|$DB_HOST|g" tribe/.env
sed -i "s|\$TRIBE_API_SECRET|$TRIBE_API_SECRET|g" tribe/.env

# PHPmyadmin config update
sed -i "s|\$DB_HOST|$DB_HOST|g" tribe/config.inc.php

echo ""
echo "${GREEN}All done. Re-run the script with 'deploy' option${RESET}"
