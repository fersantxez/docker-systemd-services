#!/bin/bash
export CONTAINER="ddns"
export IMAGE="davd/docker-ddns:1.3.0"

ZONE="myexampledomain.net"
RECORD_TTL=3600
SHARED_SECRET="changeme"
#########################
DNS_TCP_PORT=53
DNS_UDP_PORT=53
DDNS_API_PORT=8080
BIND_MOUNT_PATH="/var/cache/bind" #for persistence across reboots

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
        -e ZONE=$ZONE \
	-e RECORD_TTL=$RECORD_TTL \
	-e SHARED_SECRET=$SHARED_SECRET  \
	$IMAGE

echo "** Started "$CONTAINER" from "$IMAGE

