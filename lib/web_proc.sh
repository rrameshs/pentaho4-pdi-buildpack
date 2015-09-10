#!/usr/bin/env bash

# A dummy process that just sleeps forever to prevent the health manager from restarting the container
while :
do 
	echo "Web process sleeping..."
	sleep 365d
	echo "Web process woke up on $(date)"
done