#/bin/sh

# Usage: <instance name> <image version> <data directory path>

docker run --name $1 -v $3:/var/lib/postgresql/data -d gwt-database:$2

docker run \
	   --name "$NODE_NAME" \
	   --net techpl-net \
	   -v /opt/harayfia/data/db:/var/lib/mysql \
	   -e MYSQL_ROOT_PASSWORD=XXX \
	   -e MYSQL_DATABASE=techpl-back-db \
	   -e MYSQL_USER=techpl-back-api \
	   -e MYSQL_PASSWORD=123456789 \
	   -p 3306:3306/tcp \
-d "harayfia/back-db:${NODE_VERSION}"