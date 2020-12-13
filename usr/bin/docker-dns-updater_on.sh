#!/bin/bash
export CONTAINER="dns_updater"
export IMAGE="fernandosanchez/dns-updater"

DNS_HOST="dns-server-hostname.domain.com"
DNS_PORT=8080
DNS_SECRET="notasecret"
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
-e HOST=${DNS_HOST} \
-e PORT=${DNS_PORT} \
-e SECRET=${DNS_SECRET} \
-e DOMAIN=${DOMAIN} \
$IMAGE

echo "** Started "$CONTAINER" from "$IMAGE
