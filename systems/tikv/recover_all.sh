#!/bin/bash

echo Recovering everything ...
for f in tidb-docker-compose/workdir/* ; do
	sudo rm -rf $f/data
	cp -r $f/data.snapshot $f/data 
	echo $(basename $f)
done
