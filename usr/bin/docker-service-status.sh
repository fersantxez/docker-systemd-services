#!/bin/bash

PREFIX="docker-"

for i in \
	$(systemctl list-unit-files|grep ${PREFIX}|awk '{print $1}');
do
	systemctl status $i|head -3
done
