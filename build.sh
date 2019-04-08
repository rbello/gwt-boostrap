#!/bin/bash

cd /opt/cim3/

rm -rf /opt/cim3/database/1
rm -rf /opt/cim3/database/2
rm -rf logs
mkdir /opt/cim3/database/1
mkdir /opt/cim3/database/2
mkdir logs

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
B='\033[1m'
NC='\033[0m'
UL='\033[4m'

printf "${YELLOW}Recupération des images docker...${NC}\n"

docker pull postgres:9.4
docker pull tomcat:8

docker network create cim3-network

#docker swarm init

DB1_USER=cim3
DB1_PASSWORD=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
DB1_PASSWORD=aPF9yt82
sleep 1
DB2_USER=cim3
DB2_PASSWORD=$(date +%s | sha256sum | base64 | head -c 32 ; echo)

printf "${YELLOW}Nettoyage...${NC}\n"
docker kill cim3-data-1
docker rm cim3-data-1

docker kill cim3-data-2
docker rm cim3-data-2

docker kill cim3-gestion
docker rm cim3-gestion

printf "${YELLOW}Lancement des bases de données...${NC}\n"
docker run \
	--name "cim3-data-1" \
	--net "cim3-network" \
	-p 5432:5432/tcp \
	-e "POSTGRES_PASSWORD=$DB1_PASSWORD" \
	--volume /opt/cim3/database/1:/var/lib/postgresql/data \
	--detach postgres:9.4

#docker run \
#	--name "cim3-data-2" \
#	--net "cim3-network" \
#	--volume /opt/cim3/database/2:/var/lib/postgresql/data \
#	--detach postgres:9

sleep 10

printf "${YELLOW}Installation des données sur la base : cim_admin${NC}\n"
DB1_DATAFILE=cim_admin.backup
docker exec cim3-data-1 mkdir /backups
docker cp "database/$DB1_DATAFILE" cim3-data-1:/backups
docker exec -it cim3-data-1 psql -U postgres -c "CREATE DATABASE cim_admin;"
docker exec -it cim3-data-1 psql -U postgres -c \
 "CREATE USER ${DB1_USER} SUPERUSER PASSWORD '${DB1_PASSWORD}'; \
  GRANT ALL PRIVILEGES ON DATABASE cim_admin TO ${DB1_USER};"
docker exec cim3-data-1 psql -U postgres -l
docker exec cim3-data-1 pg_restore -U postgres -d cim_admin "/backups/$DB1_DATAFILE"
docker exec cim3-data-1 psql -U postgres

#printf "${YELLOW}Installation des données sur la base 2${NC}\n"
DB2_DATAFILE=cim_01004_amberieu_en_bugey.backup
#docker exec cim3-data-2 mkdir /backups
#docker cp "database/$DB2_DATAFILE" cim3-data-1:/backups
#docker exec -it cim3-data-2 psql -U postgres -c "CREATE DATABASE cim3db2;"
#docker exec -it cim3-data-2 psql -U postgres -c \
# "CREATE USER ${DB2_USER} SUPERUSER PASSWORD '${DB2_PASSWORD}'; \
#  GRANT ALL PRIVILEGES ON DATABASE cim3db2 TO ${DB2_USER};"
#docker exec cim3-data-2 psql -U postgres -l
#docker exec cim3-data-1 pg_restore -U postgres -d cim_admin "/backups/$DB2_DATAFILE"

printf "${YELLOW}Configuration des outils d'administration...${NC}\n"
ADMIN_PWD=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
REP='(username="admin" password=")[^"]+"'
sed -r -i "s/${REP}/\1${ADMIN_PWD}\"/" back/tomcat-users.xml
printf "  ${RED}Manager TOMCAT${NC} : admin / $ADMIN_PWD\n"

printf "${YELLOW}Installation de l'application Web${NC}\n"
cd /opt/cim3/back
docker build -t cim3-back/v3 .
JAVA_OPTS=""
docker run \
	--name "cim3-gestion" \
	--net "cim3-network" \
	--env "CATALINA_HOME=/usr/local/tomcat/" \
	-v "/opt/cim3/logs:/usr/local/tomcat/logs" \
	-e "JAVA_OPTS=$JAVA_OPTS" \
	-p 80:8080/tcp \
	-d "cim3-back/v3"

printf "${YELLOW}L'application est lancée !${NC}\n"
printf "${YELLOW}  Connectez vous sur :${NC} ${UL}http://${HOSTNAME}.ovh.net/gestion/${NC}\n"
printf "  ${RED}Credentials DB :${NC} host: cim3-data-1  login: ${DB1_USER}  password: ${DB1_PASSWORD}\n"
printf "  ${RED}Manager POSTGRES directlry: docker exec -it cim3-data-1 psql -U cim3 cim_admin${NC}\n"
printf "  ${RED}Manager TOMCAT :${NC} http://${HOSTNAME}.ovh.net/manager/html (login: admin  password: ${ADMIN_PWD})\n"

#TODAY=$(date +"%Y-%m-%d")
#tail -f "/opt/cim3/logs/catalina.$TODAY.log"

# docker exec -it cim3-data-1 psql -U cim3 cim_admin -c "select * from utilisateur"
# docker exec -it cim3-data-1 psql -U cim3 cim_admin -c "select * from utilisateur where nom = 'trust'"
# Pwd : fbf81a82a77da87d2b2fbce713d56dc6  (2812)
# docker exec -it cim3-data-1 psql -U cim3 cim_admin -c "insert into commune_accessible values (734, 2812)"
# docker exec -it cim3-data-1 psql -U cim3 cim_admin -c "select * from commune_accessible where id_utilisateur = 2812"
