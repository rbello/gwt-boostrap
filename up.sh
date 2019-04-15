#!/bin/bash

BASE_DIR="/opt/cim3"

cd "$BASE_DIR"

rm -rf "data/1" "data/2" "logs"
mkdir -p "data/1" "data/2" "logs"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
B='\033[1m'
NC='\033[0m'
UL='\033[4m'

DB1_USER=cim3
DB1_PASSWORD=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
DB1_PASSWORD=aPF9yt82
sleep 1
DB2_USER=cim3
DB2_PASSWORD=$(date +%s | sha256sum | base64 | head -c 32 ; echo)

printf "${YELLOW}Recupération des images docker...${NC}\n"

docker pull postgres:9.4
docker pull tomcat:8
docker pull dpage/pgadmin4

printf "${YELLOW}Nettoyage...${NC}\n"

docker kill cim3-data-1
docker rm cim3-data-1

docker kill cim3-data-2
docker rm cim3-data-2

docker kill cim3-gestion
docker rm cim3-gestion

docker kill tools-pgadmin
docker rm tools-pgadmin

docker network rm cim3-network

printf "${YELLOW}Création du réseau docker...${NC}\n"

docker network create cim3-network

printf "${YELLOW}Lancement des bases de données...${NC}\n"

cd "$BASE_DIR/node-data-1"
docker build -t cim3/db .

docker run \
	--name "cim3-data-1" \
	--net "cim3-network" \
	-p 5432:5432/tcp \
	-e "POSTGRES_PASSWORD=$DB1_PASSWORD" \
	--volume /opt/cim3/data/1:/var/lib/postgresql/data \
	--detach "cim3/db"

docker run \
	--name "cim3-data-2" \
	--net "cim3-network" \
	--volume /opt/cim3/data/2:/var/lib/postgresql/data \
	--detach "cim3/db"

sleep 10

printf "${YELLOW}Installation des données sur la base : cim_admin${NC}\n"
cd "$BASE_DIR"
DB1_DATAFILE=cim_admin.backup
docker exec cim3-data-1 mkdir /backups
docker cp "node-data-1/$DB1_DATAFILE" cim3-data-1:/backups
docker exec -it cim3-data-1 psql -U postgres -c "CREATE DATABASE cim_admin;"
docker exec -it cim3-data-1 psql -U postgres -c \
 "CREATE USER ${DB1_USER} SUPERUSER PASSWORD '${DB1_PASSWORD}'; \
  GRANT ALL PRIVILEGES ON DATABASE cim_admin TO ${DB1_USER};"
docker exec cim3-data-1 psql -U postgres -l
docker exec cim3-data-1 pg_restore -U postgres -d cim_admin "/backups/$DB1_DATAFILE"
docker exec cim3-data-1 psql -U postgres

#printf "${YELLOW}Installation des données sur la base : amberieu_en_bugey${NC}\n"
DB2_DATAFILE=cim_01004_amberieu_en_bugey.backup
docker exec cim3-data-2 mkdir /backups
docker cp "node-data-2/$DB2_DATAFILE" cim3-data-2:/backups
docker exec -it cim3-data-2 psql -U postgres -c "CREATE DATABASE cim_data;"
docker exec -it cim3-data-2 psql -U postgres -c \
 "CREATE USER ${DB2_USER} SUPERUSER PASSWORD '${DB2_PASSWORD}'; \
  GRANT ALL PRIVILEGES ON DATABASE cim_data TO ${DB2_USER};"
docker exec cim3-data-2 psql -U postgres -l
docker exec cim3-data-2 pg_restore -U postgres -d cim_admin "/backups/$DB2_DATAFILE"

printf "${YELLOW}Configuration des outils d'administration...${NC}\n"
ADMIN_PWD=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
REP='(username="admin" password=")[^"]+"'
sed -r -i "s/${REP}/\1${ADMIN_PWD}\"/" node-back/tomcat-users.xml

cd "$BASE_DIR/node-tools-pgadmin"
docker build -t tool-pgadmin/v3 .
docker run \
        --name "tools-pgadmin" \
        --net "cim3-network" \
        -p 81:80 \
        -e "PGADMIN_DEFAULT_EMAIL=dev@trustingenierie.com" \
        -e "PGADMIN_DEFAULT_PASSWORD=MDI2OWFjZTMwM2MzMGMxOD" \
	-v "/database/servers.json:/servers.json" \
        -d "tool-pgadmin/v3"

printf "${YELLOW}Installation de l'application Web${NC}\n"
cd "$BASE_DIR/node-back/"
docker build -t cim3-back/v3 .
JAVA_OPTS=""
docker run \
	--name "cim3-gestion" \
	--net "cim3-network" \
	--env "CATALINA_HOME=/usr/local/tomcat/" \
	-v "/opt/cim3/data/logs:/usr/local/tomcat/logs" \
	-e "JAVA_OPTS=$JAVA_OPTS" \
	-p 80:8080/tcp \
	-d "cim3-back/v3"

printf "${YELLOW}L'application est lancée !${NC}\n"
printf "  ${GREEN}Backoffice :${NC}     ${UL}http://${HOSTNAME}.ovh.net/gestion/${NC}             trust                      trustingenierie\n"
printf "  ${GREEN}Database 1 :${NC}     ${UL}jdbc:postgresql://cim3-data-1:5432/cim_admin${NC}  ${DB1_USER}                       ${DB1_PASSWORD}\n"
printf "  ${GREEN}Database 2 :${NC}     ${UL}jdbc:postgresql://cim3-data-2:5432/cim_data${NC}   ${DB2_USER}                       ${DB2_PASSWORD}\n"
printf "  ${GREEN}Manager TOMCAT :${NC} ${UL}http://${HOSTNAME}.ovh.net/manager/html${NC}         admin                      ${ADMIN_PWD}\n"
printf "  ${GREEN}Manage database:${NC} ${UL}http://${HOSTNAME}.ovh.net:81/${NC}                  dev@trustingenierie.com    MDI2OWFjZTMwM2MzMGMxOD\n"

#TODAY=$(date +"%Y-%m-%d")
#tail -f "/opt/cim3/logs/catalina.$TODAY.log"

# docker exec -it cim3-data-1 psql -U cim3 cim_admin -c "select * from utilisateur"
# docker exec -it cim3-data-1 psql -U cim3 cim_admin -c "select * from utilisateur where nom = 'trust'"
# Pwd : fbf81a82a77da87d2b2fbce713d56dc6  (2812)
# docker exec -it cim3-data-1 psql -U cim3 cim_admin -c "insert into commune_accessible values (734, 2812)"
# docker exec -it cim3-data-1 psql -U cim3 cim_admin -c "select * from commune_accessible where id_utilisateur = 2812"
