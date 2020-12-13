#!/bin/bash
export CONTAINER="docker-transmission-ovpn"
export IMAGE="haugene/transmission-openvpn:latest"
export RUNASUSER="fersanchez"
export PUID=$(id -u ${RUNASUSER})
export PGID=$(id -g ${RUNASUSER})
export OPENVPN_USERNAME="YOURUSERNAME"
export OPENVPN_PASSWORD="YOURPASSWORD"
export TRANSMISSION_USERNAME="YOURUSERNAME"
export TRANSMISSION_PASSWORD="YOURPASSWORD"
export OVPN_WEB_PORT=9091
export OVPN_TCP_PORT=51413
export OVPN_UDP_PORT=51413
export DOWNLOADS_PATH=$(eval echo "~${RUNASUSER}/Downloads")
#NOTE: This directory needs to be created and include two files
#these files are created with info from your VPN provider 
#https://www.expressvpn.com/setup#manual
#"auth.txt": encrypted username and password from the provider
#"default.ovpn": configuration from provider including server location to usE
#https://haugene.github.io/docker-transmission-openvpn/supported-providers/#using_a_custom_provider
export CREDENTIALS_PATH="/etc/docker-transmission-ovpn/custom"
export AUTH_TXT=${CREDENTIALS_PATH}"/auth.txt"
export DEFAULT_OVPN=${CREDENTIALS_PATH}"/default.ovpn"

if [ -d "$DOWNLOADS_PATH" ]; then
	echo "** Downloads dir ${DOWNLOADS_PATH} found."
else
	echo "** ERROR: Downloads dir ${DOWNLOADS_PATH} not found"
	echo "** Please review the configuration and ensure it exists"
	echo "** Exiting."
	exit 1
fi

if [ -f "$AUTH_TXT" ]; then
	echo "** Auth file ${AUTH_TXT} found."
else
	echo "** ERROR: Auth file ${AUTH_TXT} not found"
	echo "** Please download from https://www.expressvpn.com/setup#manual"
	echo "** For details check:"
	echo "https://haugene.github.io/docker-transmission-openvpn/supported-providers/#using_a_custom_provider"
	echo "** Exiting."
	exit 1
fi

if [ -f "$DEFAULT_OVPN" ]; then
	echo "** OpenVPN config file ${DEFAULT_OVPN} found."
else
	echo "** ERROR: OpenVPN config file ${DEFAULT_OVPN} not found"
        echo "** Please download from https://www.expressvpn.com/setup#manual"
	echo "** For details check:"
	echo "https://haugene.github.io/docker-transmission-openvpn/supported-providers/#using_a_custom_provider"
        echo "** Exiting."
	exit 1
fi

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
-e CREATE_TUN_DEVICE="true" \
-e WEBPROXY_ENABLED="false" \
-e LOCAL_NETWORK=10.52.0.0/24 \
-e OPENVPN_PROVIDER="CUSTOM" \
-e OPENVPN_OPTS="--inactive 3600 --ping 10 --ping-exit 300"
-e OPENVPN_USERNAME=${OPENVPN_USERNAME} \
-e OPENVPN_PASSWORD=${OPENVPN_PASSWORD} \
-e PGID=${PGID} \
-e PUID=${PUID} \
-e TRANSMISSION_RPC_AUTHENTICATION_REQUIRED="true" \
-e TRANSMISSION_RPC_USERNAME=${TRANSMISSION_USERNAME} \
-e TRANSMISSION_RPC_PASSWORD=${TRANSMISSION_PASSWORD} \
-v ${CREDENTIALS_PATH}:/etc/openvpn/custom \
-v ${DOWNLOADS_PATH}:/data \
-p ${OVPN_WEB_PORT}:9091 \
-p ${OVPN_TCP_PORT}:51413/tcp \
-p ${OVPN_UDP_PORT}:51413/udp \
$IMAGE

echo "** Started "$CONTAINER" from "$IMAGE
echo "** Access Transmission UI at http://MY_IP:"${OVPN_WEB_PORT}
