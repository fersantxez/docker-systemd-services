#!/bin/bash
export CONTAINER="transmission-ovpn"
export IMAGE="haugene/transmission-openvpn:latest"
export RUNASUSER="fersanchez"
export PUID=$(id -u ${RUNASUSER})
export PGID=$(id -g ${RUNASUSER})
export LOCAL_NETWORK="192.168.0.0/16" #Host network
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
export CREDENTIALS_PATH="/etc/docker-transmission-ovpn/custom/"
export AUTH_TXT=${CREDENTIALS_PATH}"auth.txt"
export DEFAULT_OVPN=${CREDENTIALS_PATH}"default.ovpn"
#use a subdir in the user's home folder for credentials (or swap here instead)
export USERPASS_PATH=$(eval echo "~${RUNASUSER}/.ssh/transmission-ovpn/")
export OPENVPN_USERNAME_FILE=${USERPASS_PATH}"ovpn_username"
export OPENVPN_PASSWORD_FILE=${USERPASS_PATH}"ovpn_password"
export TRANSMISSION_USERNAME_FILE=${USERPASS_PATH}"transmission_username"
export TRANSMISSION_PASSWORD_FILE=${USERPASS_PATH}"transmission_password"

if [ -d "$DOWNLOADS_PATH" ]; then
	echo "** Downloads dir ${DOWNLOADS_PATH} found."
else
	echo "** ERROR: Downloads dir ${DOWNLOADS_PATH} not found"
	echo "** Please review the configuration and make sure it exists"
	echo "** Exiting."
	exit 1
fi

declare -a REQUIRED_FILES=( \
	${AUTH_TXT} \
	${DEFAULT_OVPN} \
	${OPENVPN_USERNAME} \
	${OPENVPN_PASSWORD} \
	${TRANSMISSION_USERNAME} \
	${TRANSMISSION_PASSWORD} \
)

for REQUIRED_FILE in "${REQUIRED_FILES[@]}"; do 
	if [ -f "$REQUIRED_FILE" ]; then
		echo "** Config file ${REQUIRED_FILE} found."
	else
		echo "** ERROR: Config file ${REQUIRED_FILE} not found"
		echo "** Please check: "
		echo "https://www.expressvpn.com/setup#manual"
		echo "https://haugene.github.io/docker-transmission-openvpn/supported-providers/#using_a_custom_provider"
		echo "** Exiting."
		exit 1
	fi

done

echo "** Also please MAKE SURE to edit "${DEFAULT_OVPN}" and change the line:"
echo "auth-user-pass"
echo "** to:"
echo "auth-user-pass /etc/openvpn/custom/auth.txt"
echo "Ref: https://github.com/haugene/docker-transmission-openvpn/issues/497" 

export OPENVPN_USERNAME=$(cat ${OPENVPN_USERNAME_FILE})
export OPENVPN_PASSWORD=$(cat ${OPENVPN_PASSWORD_FILE})
export TRANSMISSION_USERNAME=$(cat ${TRANSMISSION_USERNAME_FILE})
export TRANSMISSION_PASSWORD=$(cat ${TRANSMISSION_PASSWORD_FILE})

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
--privileged \
-e CREATE_TUN_DEVICE="true" \
-e WEBPROXY_ENABLED="false" \
-e LOCAL_NETWORK=${LOCAL_NETWORK} \
-e OPENVPN_PROVIDER="CUSTOM" \
-e OPENVPN_OPTS="--inactive 3600 --ping 10 --ping-exit 300" \
-e OPENVPN_USERNAME=${OPENVPN_USERNAME} \
-e OPENVPN_PASSWORD=${OPENVPN_PASSWORD} \
-e PGID=${PGID} \
-e PUID=${PUID} \
-e TRANSMISSION_RPC_AUTHENTICATION_REQUIRED="true" \
-e TRANSMISSION_RPC_USERNAME=${TRANSMISSION_USERNAME} \
-e TRANSMISSION_RPC_PASSWORD=${TRANSMISSION_PASSWORD} \
-v ${CREDENTIALS_PATH}/default.ovpn:/etc/openvpn/custom/default.ovpn \
-v ${CREDENTIALS_PATH}/auth.txt:/etc/openvpn/custom/auth.txt \
-v ${DOWNLOADS_PATH}:/data \
-p ${OVPN_WEB_PORT}:9091 \
-p ${OVPN_TCP_PORT}:51413/tcp \
-p ${OVPN_UDP_PORT}:51413/udp \
$IMAGE

echo "** Started "$CONTAINER" from "$IMAGE
echo "** Access Transmission UI at http://MY_IP:"${OVPN_WEB_PORT}
