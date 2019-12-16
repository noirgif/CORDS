#!/bin/bash

echo Recovering everything ...
for f in tidb-docker-compose/workdir/{pd,tikv}? ; do
	sudo rm -rf $f/data
	cp -r $f/data.snapshot $f/data 
	echo $(basename $f)
done
