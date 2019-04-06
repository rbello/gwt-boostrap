#/bin/bash

docker pull postgres:9
docker pull tomcat:8

docker network create cim3-network

#docker swarm init

DB1_USER=cim3
DB1_PASSWORD=XXX

DB2_USER=cim3
DB2_PASSWORD=XXX

echo "Nettoyage..."
docker kill cim3-data-1
docker rm cim3-data-1

docker kill cim3-data-2
docker rm cim3-data-2

docker kill cim3-gestion
docker rm cim3-gestion

echo "Lancement des bases de données 1 et 2"
docker run \
	--name "cim3-data-1" \
	--net "cim3-network" \
	--volume /opt/cim3/database/1:/var/lib/postgresql/data \
	--detach postgres:9

docker run \
	--name "cim3-data-1" \
	--net "cim3-network" \
	--volume /opt/cim3/database/2:/var/lib/postgresql/data \
	--detach postgres:9

echo "Installation des données sur la base 1"
docker cp my_data1.backup cim3-data-1:/backups
docker exec -it cim3-data-1 psql -U postgres -c "CREATE DATABASE cim3db1;"
docker exec -it cim3-data-1 -U postgres -c \
 "CREATE USER ${DB1_USER} SUPERUSER PASSWORD '${DB1_PASSWORD}'; \
  GRANT ALL PRIVILEGES ON DATABASE cim3db1 TO ${DB1_USER};"
docker exec cim3-data-1 psql -U postgres -l
docker exec cim3-data-1 pg_restore -U postgres -d cim3db1 /backups/my_data1.backup

echo "Installation des données sur la base 2"
docker cp my_data2.backup cim3-data-2:/backups
docker exec -it cim3-data-2 psql -U postgres -c "CREATE DATABASE cim3db2;"
docker exec -it cim3-data-2 -U postgres -c \
 "CREATE USER ${DB2_USER} SUPERUSER PASSWORD '${DB2_PASSWORD}'; \
  GRANT ALL PRIVILEGES ON DATABASE cim3db1 TO ${DB2_USER};"
docker exec cim3-data-2 psql -U postgres -l
docker exec cim3-data-2 pg_restore -U postgres -d cim3db2 /backups/my_data2.backup

echo 