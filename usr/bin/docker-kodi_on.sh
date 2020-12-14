#!/bin/bash
export CONTAINER="kodi"
export IMAGE="linuxserver/kodi-headless:159"

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
-v /mnt/RAID1/KODI/.kodi:/config/.kodi \
-v /mnt/RAID1/Video:/Video \
-v /mnt/RAID1/Audio:/Audio \
-v /mnt/RAID1/Pictures:/Pictures \
-e PGID=1001 -e PUID=1001 \
-e TZ="America/New_York" \
-p 8080:8080 \
-p 9777:9777/udp \
$IMAGE

echo "** Started "$CONTAINER" from "$IMAGE
