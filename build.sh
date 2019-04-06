#/bin/bash

# Usage: <postgres version> <tomcat version>

DIR_BASE="/opt/cim3/"
PROG_NAME=$0

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
B='\033[1m'
NC='\033[0m'

OS_NAME=$(uname -s)
OS_VERSION=$(uname -r)
printf "Plateforme   : [${GREEN}OK${NC}] OS=${OS_NAME} Version=${OS_VERSION}\n"

printf -- "--- [${YELLOW} Construction du réseau de communication interne à l'application... ${NC}] ---\n"
docker network create gwt-network

printf -- "--- [${YELLOW} Construction de la base de données Postgres v${1}... ${NC}] ---\n"
docker kill gwt-database
docker rm gwt-database
docker pull postgres:$1

printf -- "--- [${YELLOW} Construction du serveur d'application Tomcat v${2}... ${NC}] ---\n"
docker kill gwt-appsrv
docker rm gwt-appsrv
docker pull tomcat:$2
