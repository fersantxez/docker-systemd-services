#!/bin/bash
export CONTAINER="plex"
#export IMAGE="plexinc/pms-docker:1.13.9.5456-ecd600442"
export IMAGE="plexinc/pms-docker" #latest

MY_PLEX_CLAIM="claim-CHANGEME"
SHARE_PATH="/share" #Change to the share path
WEB_PORT=32400
PUBLIC_IP=1.2.3.4 #IP to advertise (in case it's not my interface)
TRANSCODE_DIR="/tmp/plex/transcode" #avoid transcode over NAS

echo "** Removing previous instances of "$CONTAINER

/usr/bin/docker ps -q --filter "name=$CONTAINER" \
	| grep -q . \
	&& /usr/bin/docker stop $CONTAINER \
	&& /usr/bin/docker rm -fv $CONTAINER

echo "** Creating transcode dir "${TRANSCODE_DIR}
mkdir -p ${TRANSCODE_DIR}

echo "** Starting "$CONTAINER

/usr/bin/docker run \
--name $CONTAINER \
-d \
--restart=always \
--net=host \
-e TZ=America/New_York \
-e PLEX_CLAIM=${MY_PLEX_CLAIM} \
-e ADVERTISE_IP=${PUBLIC_IP} \
-v ${SHARE_PATH}"/plexconfig":/config \
-v ${TRANSCODE_DIR}:/transcode \
-v ${SHARE_PATH}/Video:/Video \
-v ${SHARE_PATH}/Audio:/Audio \
-v ${SHARE_PATH}/Pictures:/Pictures \
-p ${WEB_PORT}:32400 \
-p 3005:3005/tcp \
-p 8324:8324/tcp \
-p 32469:32469/tcp \
-p 1900:1900/udp \
-p 32410:32410/udp \
-p 32412:32412/udp \
-p 32413:32413/udp \
-p 32414:32414/udp \
$IMAGE

echo "** Started "$CONTAINER" from "$IMAGE
