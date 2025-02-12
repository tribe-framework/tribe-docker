#!/usr/bin/env bash

## deploy the app
if [[ $1 == "deploy" ]]; then
    chown -R www-data: *

    docker compose up -d

    sleep 30

    source .shell_vars

    docker exec -i {$DB_HOST} mysql -u{$DB_USER} -p{$DB_PASS} {$DB_NAME} < ./tribe/install/db.sql
    while [ $? -eq 1 ]; do
        docker exec -i {$DB_HOST} mysql -u{$DB_USER} -p{$DB_PASS} {$DB_NAME} < ./tribe/install/db.sql
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
    APP_URL="https://$APP_DOMAIN"
else
    WEB_BARE_URL="http://$WEB_BARE_URL"
    JUNCTION_URL="http://$JUNCTION_URL"
    APP_URL="http://$APP_URL"
fi

## Start updating files with user input
# docker-compose.yml
echo ""
echo "Updating docker-compose.yml"
sed -i "s|\$APP_UID|$APP_UID|g" docker-compose.yml
sed -i "s|\$DB_USER|$DB_USER|g" docker-compose.yml
sed -i "s|\$DB_PASS|$DB_PASS|g" docker-compose.yml
sed -i "s|\$DB_NAME|$DB_NAME|g" docker-compose.yml
sed -i "s|\$TRIBE_PORT|$TRIBE_PORT|g" docker-compose.yml
sed -i "s|\$JUNCTION_PORT|$JUNCTION_PORT|g" docker-compose.yml
echo "Done"

# .env file
echo""
echo "Setting up environment for tribe"
cp tribe/.env.sample tribe/.env
sed -i "s|\$APP_NAME|$APP_NAME|g" tribe/.env
sed -i "s|\$JUNCTION_PASS|$JUNCTION_PASS|g" tribe/.env
sed -i "s|\$WEB_BARE_URL|$WEB_BARE_URL|g" tribe/.env
sed -i "s|\$APP_URL|$APP_URL|g" tribe/.env
sed -i "s|\$WEB_URL|$WEB_URL|g" tribe/.env
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
echo "Done"

echo "DB_HOST=${DB_HOST}" >  .shell_vars
echo "DB_USER=${DB_USER}" >> .shell_vars
echo "DB_PASS=${DB_PASS}" >> .shell_vars
echo "DB_NAME=${DB_NAME}" >> .shell_vars
chmod 400 .shell_vars

echo ""
echo "All Done!!. Re-run the script with 'deploy' option"
