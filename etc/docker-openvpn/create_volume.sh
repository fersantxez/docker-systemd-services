#!/bin/bash
export OVPN_DATA="ovpn-data-volume"

docker volume create --name $OVPN_DATA

