#!/bin/bash
export CONTAINER="plex"
export IMAGE="plexinc/pms-docker:1.13.9.5456-ecd600442"

MY_PLEX_CLAIM="claim-CHANGEME"
SHARE_PATH="/share" #Change to the share path

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
-e TZ=America/New_York \
-e PLEX_CLAIM=$MY_PLEX_CLAIM \
-v ${SHARE_PATH}"/PLEX/Library/Application Support/Plex Media Server":/config \
-v /home/nobody/plex_temp/transcode:/transcode \
-v ${SHARE_PATH}/Video:/Video \
-v ${SHARE_PATH}/Audio:/Audio \
-v ${SHARE_PATH}/Pictures:/Pictures \
$IMAGE

echo "** Started "$CONTAINER" from "$IMAGE
