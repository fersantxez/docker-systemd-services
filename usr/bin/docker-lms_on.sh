#!/bin/bash
export CONTAINER="lms"
export IMAGE="lmscommunity/logitechmediaserver:8.1.0"

SHARE_PATH="/share" #Change to the share path
MUSIC_PATH=${SHARE_PATH}"/Audio/0_Music"
LMS_PATH=${SHARE_PATH}"/LMS"
CONFIG_PATH=${LMS_PATH}"/config"
PLAYLIST_PATH=${LMS_PATH}"/playlist"

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
-v ${CONFIG_PATH}:"/config" \
-v ${MUSIC_PATH}/:"/music" \
-v ${PLAYLIST_PATH}:"/playlist":rw \
-v "/etc/localtime":"/etc/localtime":ro \
-v "/etc/timezone":"/etc/timezone":ro \
-p 9000:9000/tcp \
-p 9090:9090/tcp \
-p 3483:3483/tcp \
-p 3483:3483/udp \
$IMAGE

echo "** Started "$CONTAINER" from "$IMAGE
