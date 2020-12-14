#!/bin/bash
export CONTAINER="ddns"
export IMAGE="fernandosanchez/dns-updater"

HOST=ddns.api.hostname.domain.org
DNS_SECRET=CHANGEME
PORT=8080
DOMAIN=$(hostname)


echo "** Removing previous instances of "$CONTAINER

/usr/bin/docker ps -q --filter "name=$CONTAINER" \
	| grep -q . \
	&& /usr/bin/docker stop $CONTAINER \
	&& /usr/bin/docker rm -fv $CONTAINER

echo "** Starting "$CONTAINER

/usr/bin/docker run \
--name $CONTAINER \
-d \
--restart=always \
--net=host \
-e HOST=$HOST \
-e SECRET=$DNS_SECRET \
-e PORT=$PORT \
-e DOMAIN=$DOMAIN \
$IMAGE

echo "** Started "$CONTAINER" from "$IMAGE
