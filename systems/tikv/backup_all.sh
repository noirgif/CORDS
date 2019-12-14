#!/bin/bash

echo Backing up everything ...
for f in tidb-docker-compose/workdir/* ; do
	sudo rm -rf $f/data.snapshot
	cp -r $f/data $f/data.snapshot
	echo $(basename $f)
done
