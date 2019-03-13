#!/bin/bash
export CONTAINER="nodesktop"
export IMAGE="fernandosanchez/nodesktop:0.1"
export NAME=nodesktop
export VNC_COL_DEPTH=24
export VNC_RESOLUTION=1680x1050
export VNC_PW=mypassword
export NOVNC_PORT=6901
export HOME_MOUNT_DIR=/mnt/home
export ROOT_MOUNT_DIR=/mnt/root
export RAID_MOUNT_DIR=/mnt/RAID1
export MY_USERNAME=fersanchez

echo "** Removing previous instances of "$CONTAINER

/usr/bin/docker ps -q --filter "name=$CONTAINER" \
	| grep -q . \
	&& /usr/bin/docker stop $CONTAINER \
	&& /usr/bin/docker rm -fv $CONTAINER

echo "** Starting "$CONTAINER

/usr/bin/docker run \
--name $CONTAINER \
-d \
--privileged \
--restart=always \
-p ${NOVNC_PORT}:6901 \
-v /home/fersanchez:${HOME_MOUNT_DIR} \
-v /mnt/RAID1:${RAID_MOUNT_DIR} \
-v /etc/group:/etc/group:ro \
-v /etc/passwd:/etc/passwd:ro \
-v /etc/shadow:/etc/shadow:ro \
-v /etc/sudoers.d:/etc/sudoers.d:ro \
-v /var/run:/var/run \
--user 1000:1000 \
-e VNC_COL_DEPTH=${VNC_COL_DEPTH} \
-e VNC_RESOLUTION=${VNC_RESOLUTION} \
-e VNC_PW=${VNC_PW} \
$IMAGE

echo "** Started "$CONTAINER" from "$IMAGE

echo "** Started "$CONTAINER" from "$IMAGE
