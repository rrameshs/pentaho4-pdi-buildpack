#!/usr/bin/env bash

# A dummy process that just sleeps forever, occasionally waking up
# This lets the health manager know that the app is ok and doesn't need restarting
while :
do 
	echo "Web process sleeping..."
	sleep 5m
	echo "Web process woken up"
done